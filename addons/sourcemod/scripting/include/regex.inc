#if defined _regex_included
  #endinput
#endif
#define _regex_included

#include <core>

enum Regex 
{ 
REGEX_MATCH_FAIL = -2, 
REGEX_PATTERN_FAIL, 
REGEX_NO_MATCH, 
REGEX_OK 
};

/**
 * Initiates a regular expression match
 * @param str			The string used to init a regular expression match 
 * @param pattern	The pattern used to init a regular expression match
 * @param ret     It's either the number of substrings, a match error code
 * @return        The handle to use for regex functions
 */
native Handle:Regex_Match(const String:str[],const String:pattern[],&ret);

/**
 * Retrieves a matched sub string
 * @param regexhdl  The handle of the regex data
 * @param str_id    Substr ID to search for
 * @param buffer    The buffer to store to
 * @param maxlen    Max length of the return result
 * @return				Returns 0 on error
 */
native Regex_Substr(Handle:regexhdl,str_id,String:buffer[],maxlen);

/**
 * Free a regex piece of data, used to clean memory
 * @param regexhdl  The handle of the regex data
 * @return 0 means you passed a bad ID
 */
native Regex_Free(Handle:regexhdl);

/**
 * @endsection
 */

/**
 * Do not edit below this line!
 */
public Extension:__ext_tempents = 
{
	name = "Regex Extension",
	file = "regex.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
