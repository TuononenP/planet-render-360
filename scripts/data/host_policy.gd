class_name HostPolicy
extends RefCounted

## Project rule: the app never contacts a Russian-operated service or a
## Russian domain, whether built in or set through RemoteConfig. A host is
## refused when it ends in a Russian top-level domain, or is (or sits under)
## one of the well-known Russian services that use other domains.
## tests/host_policy_test.gd also fails if any such host appears in the
## project's source, so a mirror cannot come back unnoticed.

## Russian top-level domains, including the internationalised .рф.
const BLOCKED_SUFFIXES: Array[String] = [".ru", ".su", ".рф", ".xn--p1ai"]
## Russian services on other domains: a host containing one of these names
## is refused.
const BLOCKED_NAMES: Array[String] = ["yandex", "vkontakte", "rambler", "2gis"]
## Services that are exactly this domain, or any subdomain of it.
const BLOCKED_DOMAINS: Array[String] = ["vk.com", "vk.me", "userapi.com"]

## "overpass.example:8443/path?q=1" and "https://Overpass.Example/path" both
## give "overpass.example".
static func host_of(url_or_host: String) -> String:
	var rest := url_or_host.strip_edges()
	if rest.contains("://"):
		rest = rest.substr(rest.find("://") + 3)
	for stop in ["/", "?", "#"]:
		var at := rest.find(stop)
		if at >= 0:
			rest = rest.substr(0, at)
	if rest.contains("@"):
		rest = rest.substr(rest.rfind("@") + 1)
	var colon := rest.rfind(":")
	if colon >= 0 and not rest.contains("]"):
		rest = rest.substr(0, colon)
	return rest.to_lower().trim_suffix(".")

static func is_blocked(url_or_host: String) -> bool:
	var host := host_of(url_or_host)
	if host.is_empty():
		return false
	for suffix in BLOCKED_SUFFIXES:
		if host.ends_with(suffix) or host == suffix.substr(1):
			return true
	for name in BLOCKED_NAMES:
		if host.contains(name):
			return true
	for domain in BLOCKED_DOMAINS:
		if host == domain or host.ends_with("." + domain):
			return true
	return false
