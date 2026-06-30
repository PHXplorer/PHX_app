/* globals jQuery */

/**
 * The :contains selector provided by jQuery is case-sensitive.
 * This code extends custom jQuery selectors to add a case-insensitive version.
 * @example $(".myclass:icontains('some Text')");
 */
jQuery.expr[':'].icontains = (a, i, m) => jQuery(a).text().toLocaleLowerCase().indexOf(m[3].toLocaleLowerCase()) >= 0; // prettier-ignore
