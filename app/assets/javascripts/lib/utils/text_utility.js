/**
 * Adds a , to a string composed by numbers, at every 3 chars.
 *
 * 2333 -> 2,333
 * 232324 -> 232,324
 *
 * @param {String} text
 * @returns {String}
 */
export const addDelimiter = text => (text ? text.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',') : text);

/**
 * Returns '99+' for numbers bigger than 99.
 *
 * @param {Number} count
 * @return {Number|String}
 */
export const highCountTrim = count => (count > 99 ? '99+' : count);

/**
 * Converts first char to uppercase and replaces undercores with spaces
 * @param {String} string
 * @requires {String}
 */
export const humanize = string => string.charAt(0).toUpperCase() + string.replace(/_/g, ' ').slice(1);

/**
 * Adds an 's' to the end of the string when count is bigger than 0
 * @param {String} str
 * @param {Number} count
 * @returns {String}
 */
export const pluralize = (str, count) => str + (count > 1 || count === 0 ? 's' : '');

/**
 * Replaces underscores with dashes
 * @param {*} str
 * @returns {String}
 */
export const dasherize = str => str.replace(/[_\s]+/g, '-');

/**
 * Removes accents and converts to lower case
 * @param {String} str
 * @returns {String}
 */
export const slugify = str => str.trim().toLowerCase();

/**
 * Truncates given text
 *
 * @param {String} string
 * @param {Number} maxLength
 * @returns {String}
 */
export const truncate = (string, maxLength) => `${string.substr(0, (maxLength - 3))}...`;

/**
 * Capitalizes first character
 *
 * @param {String} text
 * @return {String}
 */
export function capitalizeFirstCharacter(text) {
  return `${text[0].toUpperCase()}${text.slice(1)}`;
}
