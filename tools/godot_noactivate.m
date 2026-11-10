// DYLD shim for tools/godot_bg.sh: keeps a windowed Godot run from taking
// focus on macOS. Godot activates itself and orders its window to the front
// on launch, which pulls keyboard focus away from the editor and flashes a
// blank white window. This turns those calls into no-ops.
//
// Build (the wrapper looks for it at ~/.local/lib/godot_noactivate.dylib):
//   mkdir -p ~/.local/lib
//   clang -dynamiclib -fobjc-arc -framework AppKit -framework ApplicationServices \
//       -Wno-deprecated-declarations \
//       -o ~/.local/lib/godot_noactivate.dylib tools/godot_noactivate.m
//   codesign --force --sign - ~/.local/lib/godot_noactivate.dylib
//
// GODOT_NOACTIVATE_HIDE=1 also keeps the window from being ordered on
// screen at all (rendering to viewports still works); the wrapper sets it
// for --script runs. It also keeps the window out of full screen: the
// project starts full screen and Godot's --windowed does not override
// that, so every capture would open a new Space and pull you off yours.
//
// Godot's unbundled-launch hack calls TransformProcessType to make itself
// a foreground app, which activates it; that call is refused too.

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <objc/runtime.h>

static BOOL (*orig_set_policy)(id, SEL, NSApplicationActivationPolicy);

static void no_activate_ignoring(id self, SEL _cmd, BOOL flag) {}

static void no_activate(id self, SEL _cmd) {}

static BOOL no_activate_with_options(id self, SEL _cmd, NSApplicationActivationOptions options) {
	return YES;
}

static BOOL set_policy_accessory(id self, SEL _cmd, NSApplicationActivationPolicy policy) {
	return orig_set_policy(self, _cmd, NSApplicationActivationPolicyAccessory);
}

static void order_back_not_key(id self, SEL _cmd, id sender) {
	NSWindow *window = (NSWindow *)self;
	if (getenv("GODOT_NOACTIVATE_HIDE")) {
		window.alphaValue = 0.0;
		window.ignoresMouseEvents = YES;
		return;
	}
	[window orderBack:sender];
}

static void (*orig_toggle_full_screen)(id, SEL, id);

static void windowed_only(id self, SEL _cmd, id sender) {
	if (getenv("GODOT_NOACTIVATE_HIDE")) {
		return;
	}
	orig_toggle_full_screen(self, _cmd, sender);
}

static OSStatus no_foreground(const ProcessSerialNumber *psn, ProcessApplicationTransformState state) {
	if (state == kProcessTransformToForegroundApplication) {
		return noErr;
	}
	return TransformProcessType(psn, state);
}

__attribute__((used, section("__DATA,__interpose"))) static struct {
	const void *replacement;
	const void *original;
} interpose_transform = { (const void *)no_foreground, (const void *)TransformProcessType };

static void swap(Class cls, SEL sel, IMP imp) {
	Method m = class_getInstanceMethod(cls, sel);
	if (m) {
		method_setImplementation(m, imp);
	}
}

__attribute__((constructor)) static void init(void) {
	Class app = [NSApplication class];
	swap(app, @selector(activateIgnoringOtherApps:), (IMP)no_activate_ignoring);
	swap(app, @selector(activate), (IMP)no_activate);
	swap([NSRunningApplication class], @selector(activateWithOptions:), (IMP)no_activate_with_options);
	swap([NSWindow class], @selector(makeKeyAndOrderFront:), (IMP)order_back_not_key);
	Method fs = class_getInstanceMethod([NSWindow class], @selector(toggleFullScreen:));
	if (fs) {
		orig_toggle_full_screen = (void *)method_getImplementation(fs);
		method_setImplementation(fs, (IMP)windowed_only);
	}
	Method m = class_getInstanceMethod(app, @selector(setActivationPolicy:));
	if (m) {
		orig_set_policy = (void *)method_getImplementation(m);
		method_setImplementation(m, (IMP)set_policy_accessory);
	}
}
