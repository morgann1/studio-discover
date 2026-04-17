const PACKAGE_NAME_PATTERN = /^[a-z0-9-]+$/;
const UID_PATTERN = /^[1-9]\d*$/;
const VERSION_PATTERN = /^[a-zA-Z0-9.+\-_]+$/;
const CONTROL_CHAR_PATTERN = /[\x00-\x1F\x7F]/;

const MAX_QUERY_LENGTH = 100;
const MAX_PACKAGE_NAME_LENGTH = 64;
const MAX_VERSION_LENGTH = 32;
const MAX_UID_LENGTH = 20;

export function isValidPackageName(value: string): boolean {
	return value.length > 0 && value.length <= MAX_PACKAGE_NAME_LENGTH && PACKAGE_NAME_PATTERN.test(value);
}

export function isValidUid(value: string): boolean {
	return value.length > 0 && value.length <= MAX_UID_LENGTH && UID_PATTERN.test(value);
}

export function isValidVersion(value: string): boolean {
	return value.length > 0 && value.length <= MAX_VERSION_LENGTH && VERSION_PATTERN.test(value);
}

export function isValidSearchQuery(value: string): boolean {
	return value.length > 0 && value.length <= MAX_QUERY_LENGTH && !CONTROL_CHAR_PATTERN.test(value);
}
