<!--- ------------------------------------------------------------------------- ----

    File:       SmartType.cfc
    
    Author:     Seb Duggan
	
	Version:	0.1
	
	Updated:	29/01/2007 - initial release
    
    Overview:   This is a component which takes a string and converts all
                quotes, dashes, ellipses and multiplication signs into their
                typographic equivalents - e.g. smart quotes, em/en dashes.

                All HTML tags are exempt from the conversion, as are HTML
                comment blocks. Also, all text inside some HTML elements
                (pre, code, kbd, script, math) is ignored.

                SmartType will also pre-convert any MS Word-type entities
                before it begins. There is also the option to "stupefy" - that
                is, to remove all the typographic entities from the string and
                replace them with their "dumb" counterparts.

                The component is influenced by the "SmartyPants" plug-in for
                Movable Type and Blosxom, written by John Gruber:

                    <http://daringfireball.net/projects/smartypants/>

                Note that as far as possible all string operations, matches
                and replacing is done using Java methods, to enable easy reuse
                of this code in a Java CFX tag.

    Usage:      The only publicly accessible function in the component is
                SmartType. It takes two arguments:

                Text     (required)   The text string on which to perform
                                      the conversion operations.

                Convert  (optional)   String of characters specifying which
                                      conversions to perform.

                                      If not specified, the default operations
                                      are 'deqxw'.
                                      
                                      Options are:

                                      d - Educate dashes
                                          A hyphen with a space around it will
                                          become an en-dash.
                                          Two or three hyphens will become an
                                          em-dash.
                                          
                                      e - Educate ellipses
                                          A series of three or four dots, with
                                          or without spaces in between, will
                                          become an ellipsis.

                                      q - Educate quotes
                                          All quote marks and apostrophes will
                                          be replaced by their "smart quote"
                                          equivalents.

                                      x - Educate multiply sign
                                          An 'x' with digits either side of it,
                                          optionally separated by white space,
                                          will become a typographic
                                          multiplication sign.

                                      w - Convert MS Word entities
                                          All MS Word-type smart quotes and
                                          entities will be converted to plain
                                          ASCII equivalents before the main
                                          processing is performed.

                                      stupefy - Stupefy entities
                                          All smart quotes and other HTML
                                          entities will be dumbed-down to their
                                          ASCII equivalents.

                If you wish a character not to be smartened up, it can be escaped
                by preceding it with a backslash (\), e.g.:

                    "I am 6\'2\"," he said.

                Would become:
                
                    &#8220;I am 6'2",&#8221; he said.


                To call the component from a ColdFusion page, use the <cfinvoke>
                tag, e.g.:

                    <cfinvoke component="SmartType"
                              method="SmartType"
                              Text="#myString#"
                              Convert="qdexw"
                              returnvariable="myOutput" />

                This would send the text contained in variable "myString" to the
                component, apply all operations to it, and return it to a variable
                named "myOutput".
				
	Licence:	SmartType - a typographical prettifier
				Copyright (C) 2007  Seb Duggan
				
				This program is free software; you can redistribute it and/or
				modify it under the terms of the GNU General Public License
				as published by the Free Software Foundation; either version 2
				of the License, or (at your option) any later version.
				
				This program is distributed in the hope that it will be useful,
				but WITHOUT ANY WARRANTY; without even the implied warranty of
				MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
				GNU General Public License for more details.
				
				You should have received a copy of the GNU General Public License
				along with this program; if not, write to the Free Software
				Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
    
----- ---------------------------------------------------------------------//// --->


<cfcomponent displayName="SmartType" output="no" hint="Smartens up typography by replacing text entities with smart, typographical entities.">

	<cffunction name="init" output="false" returntype="any">
		<cfreturn this />
	</cffunction>
	
    <cffunction name="SmartType" access="public" output="no" returnType="string"
                hint="Takes a string and returns it with typographical entities">
    
        <cfargument name="Text" type="string" required="yes" default=""
                    hint="String on which to perform typographic conversions" />
        <cfargument name="Convert" type="string" required="no" default=""
                    hint="Specifies which methods of SmartType to perform
                            (q: quotes; d: dashes; e: ellipses;
                             x: multiply sign; w: strip Word cruft;
                             stupefy: remove all smart formatting)" />
    
    
        <cfscript>
    
            // Initialise variables
            var thisTokenType = "";
            var thisTokenLastChar = "";
            var prevTokenLastChar = "";
            var arrTokens = ArrayNew(2);
            var TASKS = StructNew();
            var objPattern = "";
            var pattern = "";
    
            // Set up which block-level tags we want SmartType to ignore
            var tagsToSkip = "pre|code|kbd|script|math";
            var curSkipTag = "";
    
            // Initialize string buffers to make building the output more efficient
            var sb = CreateObject( "java" , "java.lang.StringBuffer" ).Init();
            var thisToken = CreateObject( "java" , "java.lang.StringBuffer" ).Init();

            // Determine which conversion tasks to perform
            TASKS.quotes = 0;
            TASKS.dashes = 0;
            TASKS.ellipses = 0;
            TASKS.multiplier = 0;
            TASKS.stupefy = 0;
            TASKS.word = 0;
            
            if ( ARGUMENTS.Convert.equals("stupefy") ) {
                
                TASKS.stupefy = 1;
                TASKS.word = 1;
                
            } else {
               
                TASKS.quotes     = ARGUMENTS.Convert.indexOf( "q" ) GTE 0
                                    or not ARGUMENTS.Convert.length();       // q - Educate quotes
                                    
                TASKS.dashes     = ARGUMENTS.Convert.indexOf( "d" ) GTE 0
                                    or not ARGUMENTS.Convert.length();       // d - Educate dashes
                                    
                TASKS.ellipses   = ARGUMENTS.Convert.indexOf( "e" ) GTE 0
                                    or not ARGUMENTS.Convert.length();       // e - Educate ellipses
                                    
                TASKS.multiplier = ARGUMENTS.Convert.indexOf( "x" ) GTE 0
                                    or not ARGUMENTS.Convert.length();       // x - Educate multiplication signs
                                    
                TASKS.word       = ARGUMENTS.Convert.indexOf( "w" ) GTE 0
                                    or not ARGUMENTS.Convert.length();       // w - Clean up MS Word cruft
                
            }
            


            // Strip MS Word cruft from the string
            if ( TASKS.word )
                ARGUMENTS.Text = StripMSWord( ARGUMENTS.Text );
            
    
            // Tokenize the text input.
            // This splits it into an array of tags and text.
            arrTokens = Tokenize( ARGUMENTS.Text );


            
            // Set up pattern matcher
            objPattern = CreateObject("java","java.util.regex.Pattern");
            
    
            // Loop over each token in the array
            for ( i = 1 ; i LTE ArrayLen( arrTokens ) ; i = i + 1 ) {
      
                thisTokenType = arrTokens[i][1];
                thisToken = arrTokens[i][2];
    
                // Is it a tag?
                if ( thisTokenType.equals("tag") ) {
    
                    // Find what tag it is
                    pattern = objPattern.compile( "/?\w+" );
                    findTag = pattern.matcher( thisToken );
                    findTag.find();
                    thisTagName = findTag.group();
    
                    // Are we currently in the middle of a tag to skip?
                    if ( curSkipTag.length() ) {
                        
                        //We are, so look to see if the tag is being closed
                        if ( thisTagName.equals("/" & curSkipTag) ) {
                            
                            // Skip tag is being closed, so reset curSkipTag variable
                            curSkipTag = "";
                            
                        }
                        
                    } else {
    
                        // We are not in the middle of a skip tag, so check
                        // to see if the current tag is in the skip tag list
                        if ( objPattern.matches( tagsToSkip , thisTagName ) ) {
    
                            // Yes it is, so set the curSkipTag variable to
                            // the current tag name
                            curSkipTag = thisTagName;
                            
                        }
                        
                    }
                    
                }
    
    
                // If the current token is a text token, and we are not
                // in the middle of a skip tag, we can process the text!
                if ( thisTokenType.equals("text") and not curSkipTag.length() ) {
    
                    // Remember the last character before processing
                    thisTokenLastChar = thisToken.toString().substring( thisToken.length() );
    
    
                    
                    // Process escaped entities
                    thisToken = ProcessEscapes( thisToken );
            
                    // Educate dashes
                    if ( TASKS.dashes )
                        thisToken = EducateDashes( thisToken );
            
                    // Educate ellipses
                    if ( TASKS.ellipses )
                        thisToken = EducateEllipses( thisToken );
            
                    // Educate multiplication signs
                    if ( TASKS.multiplier )
                        thisToken = EducateMultiplier( thisToken );
    
    
                    
    
                    // Educate quotes
                    if ( TASKS.quotes ) {
                        
                        if ( thisToken.equals("'") or thisToken.equals('"') ) {
        
                            // Special case: single-character ' token
                            if ( thisToken.equals("'") ) {
                                if (objPattern.matches( "\S", prevTokenLastChar )) {
                                    thisToken = "&##8217;";
                                } else {
                                    thisToken = "&##8216;";
                                }
                            }
        
                            // Special case: single-character " token
                            if ( thisToken.equals('"') ) {
                                if (objPattern.matches( "\S", prevTokenLastChar )) {
                                    thisToken = "&##8221;";
                                } else {
                                    thisToken = "&##8220;";
                                }
                            }
        
                        } else {
        
                            // Normal case
                            thisToken = EducateQuotes( thisToken );
                            
                        }
                        
                    }


                    // Stupefy entities
                    if ( TASKS.stupefy )
                        thisToken = StupefyEntities( thisToken );
    
                  
                }
    
                // Add the amended token to the string buffer
                sb.append( thisToken.toString() );
    
                // Remember the last character of this token
                prevTokenLastChar = thisTokenLastChar;
    
            }
    
            // Return the string buffer as a string
            return( sb.toString() );
    
        </cfscript>
    
    </cffunction>
    
    
    
    
    
    <cffunction name="EducateDashes" access="private" output="no" returnType="string"
                hint="Turns single dashes into en-dashes and double dashes into em dashes">
        
        <cfargument name="Text" type="string" required="yes" default=""
                    hint="Text string on which to perform conversions" />
        
        
        <cfscript>

            var temp = ARGUMENTS.Text;
          
            temp = temp.replaceAll( "(\s)-(\s)" , "$1&##8211;$2" );
            temp = temp.replaceAll( "(\s?)-{2,3}(\s?)" , "$1&##8212;$2" );
            
            return( temp );
        
        </cfscript>
    
    </cffunction>
    
    
    
    
    
    <cffunction name="EducateEllipses" access="private" output="no" returnType="string"
                hint="Turns sets of three or four dots (with or without spaces) into an ellipsis entity">
        
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string on which to perform conversions" />
        
        
        <cfscript>

            var temp = ARGUMENTS.Text;
    
            temp = temp.replaceAll( "(\. ?){2,3}\." , "&##8230;" );
            
            return( temp );
        
        </cfscript>
    
    </cffunction>
    
    
    
    
    
    <cffunction name="EducateMultiplier" access="private" output="no" returnType="string"
                hint="Turns an 'x' in between numbers into a multiplication sign entity">
        
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string on which to perform conversions" />
        
        
        <cfscript>

            var temp = ARGUMENTS.Text;
    
            temp = temp.replaceAll( "(\d ?)x( ?\d)" , "$1&times;$2" );
            
            return( temp );
        
        </cfscript>
    
    </cffunction>
    
    
    
    
    
    <cffunction name="EducateQuotes" access="private" output="no" returnType="string"
                hint="Turns quotes and apostrophes into the appropriate smart quotes">
        
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string on which to perform conversions" />
        
        
        <cfscript>

            var temp = ARGUMENTS.Text;
            
            // Special case: quote at start followed by puctuation at a
            // non-word-break is closing quote
            temp = temp.replaceAll( "^""(?=\p{Punct}\B)" , "&##8221;" );
            temp = temp.replaceAll( "^'(?=\p{Punct}\B)" , "&##8217;" );

            // Special case: "' or '" followed by word character are opening quotes
            temp = temp.replaceAll( "'""(?=\w)" , "&##8220;&##8216;" );
            temp = temp.replaceAll( """'(?=\w)" , "&##8216;&##8220;" );

            // Special case: decade, e.g. '80s, is closing quote
            temp = temp.replaceAll( "'(?=\d{2}s)" , "&##8217;" );

            // Quote following a space or dashes is an opening quote
            temp = temp.replaceAll( "(\s|&nbsp;|--|&[mn]dash;|&##821[12];|&##x201[34])'(?=\w)" , "$1&##8216;" );
            temp = temp.replaceAll( "(\s|&nbsp;|--|&[mn]dash;|&##821[12];|&##x201[34])""(?=\w)" , "$1&##8220;" );

            // ' preceded by non-space is closing quote
            temp = temp.replaceAll( "(\S)'" , "$1&##8217;" );
           
            // ' at the start of the string, followed by an optional "s",
            // then punctuation or space, is a closing quote
            temp = temp.replaceAll( "^'(s?[\p{Punct}\s])" , "&##8217;$1" );

            // " preceded by non-space is closing quote
            temp = temp.replaceAll( "(\S)""" , "$1&##8221;" );
           
            // " at the start of the string, followed by 
            // punctuation or space, is a closing quote
            temp = temp.replaceAll( "^""([\p{Punct}\s])" , "&##8221;$1" );

            // All remaining ' and " should be opening quotes
            temp = temp.replaceAll( """" , "&##8220;" );                    
            temp = temp.replaceAll( "'" , "&##8216;" );
                               
            
            return( temp );
        
        </cfscript>
    
    </cffunction>
    
    
    
    
    
    <cffunction name="ProcessEscapes" access="private" output="no" returnType="string"
                hint="Looks for characters escaped with a \ and pre-processes them into entities">
        
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string on which to perform conversions" />
        
        
        <cfscript>

            var temp = ARGUMENTS.Text;

            // Escape back slashes like this: \\
            temp = temp.replaceAll( "\\\\" , "&##92;" );

            // Escape single and double quotes like this: \" and \'
            temp = temp.replaceAll( "\\""" , "&##34;" );
            temp = temp.replaceAll( "\\'" , "&##39;" );

            // Escape dots like this: \...
            temp = temp.replaceAll( "\\\." , "&##46;" );

            // Escape dashes like this: \-
            temp = temp.replaceAll( "\\-" , "&##45;" );

            // Escape x like this: \x
            temp = temp.replaceAll( "\\x" , "&##120;" );
            
            return( temp );
        
        </cfscript>
    
    </cffunction>





    <cffunction name="StripMSWord" access="private" output="no" returnType="string"
                hint="Remove all MS Word's 'smart' characters from a string">
        
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string from which to remove Word cruft" />


        <cfscript>

            var temp = ARGUMENTS.Text;

            temp = temp.replaceAll( chr(8211) , "-" );
            temp = temp.replaceAll( chr(8212) , "--" );
            temp = temp.replaceAll( chr(8216) & "|" & chr(8217) , "'" );
            temp = temp.replaceAll( chr(8220) & "|" & chr(8221) , """" );
            temp = temp.replaceAll( chr(8230) , "..." );

            return( temp );

        </cfscript>

    </cffunction>
    
    
    
    
    
    <cffunction name="StupefyEntities" access="private" output="no" returnType="string"
                hint="Turns smart entities back into plain ASCII">
        
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string on which to perform conversions" />
        
        
        <cfscript>

            var temp = ARGUMENTS.Text;
    
            temp = temp.replaceAll( "&##8211;" , "-" );
            temp = temp.replaceAll( "&##8212;" , "--" );
            temp = temp.replaceAll( "&##8216;|##8217;" , "'" );
            temp = temp.replaceAll( "&##8220;|&##8221;" , """" );
            temp = temp.replaceAll( "&##8230;" , "..." );
            
            return( temp );
        
        </cfscript>
    
    </cffunction>
    
    
    
    
    
    <cffunction name="Tokenize" access="public" output="no" returnType="array"
                hint="Splits the input text into an array of tags and non-tag text">
    
        <cfargument name="Text" type="string" required="yes" default="" 
                    hint="Text string to break into tokenized array" />
    
    
        <cfscript>
    
            // Initialise variables
            var arrTokens = ArrayNew(2);
            var intPos = 0;
            var intIndex = 1;
            var pattern = "";
            var matcher = "";

    
            // Set up the maximum tag nesting level, and build regular expression
            // to search for tags or comment blocks
            var intNestLevel = 6;
            
            // Initialize string buffer to build regex
            var regex = CreateObject( "java" , "java.lang.StringBuffer" ).Init();

            // Loop to create tag nesting openings
            for ( i = 1 ; i LTE intNestLevel ; i = i + 1 ) {
                regex = regex.append( "(?:<(?:[^<>]" );
                if ( i LT intNestLevel )
                regex = regex.append( "|" );
            }
                        
            // Loop to create tag nesting closings
            for ( i = 1 ; i LTE intNestLevel ; i = i + 1 ) {
                regex = regex.append( ")*>)" );
            }
                        
            // Add regex to match comment blocks
            regex = regex.append( "|<!--.*?-->" );
            
            // Convert the StringBuffer to a string
            regex = regex.toString();
                        


            // Initialise the Java Pattern Matcher
            Pattern = CreateObject("java","java.util.regex.Pattern");
            pattern = Pattern.Compile( regex );
            matcher = pattern.Matcher( ARGUMENTS.Text );
      
    
            // Loop through the matches until we reach the end
            while ( matcher.find() ) {
    
                // The next tag doesn't start at our current position,
                // so we've got some non-tag text first
                if ( matcher.start() GT intPos ) {
    
                    // It's a text token
                    arrTokens[intIndex][1] = "text";
    
                    // It spans from the current position to the start of the tag
                    arrTokens[intIndex][2] = ARGUMENTS.Text.substring( intPos , matcher.start() );
    
                    // Increase intIndex by 1, so the tag gets put in the
                    // next row of the array
                    intIndex = intIndex + 1;
                    
                }


                // Then we get to the tag token...
                arrTokens[intIndex][1] = "tag";

                // The whole tag is contained in the Matcher.group() method
                arrTokens[intIndex][2] = matcher.group();

                // Move the current position to after the end of the tag
                intPos = matcher.end();
    
                // Increase intIndex by 1, ready for the next token
                intIndex = intIndex + 1;
        
            }


            // No more tags found in the text, so add last bit of the string
            // as a text token if we're not already at the end of the string
            if ( intPos LT ARGUMENTS.Text.length() ) {
                
                // It's a text token
                arrTokens[intIndex][1] = "text";
                
                // It spans from the current position to the end of the text
                arrTokens[intIndex][2] = ARGUMENTS.Text.substring( intPos );
                
            }
    
    
            // Return the array of tokens
            return( arrTokens );
    
        </cfscript>
      
    </cffunction>


</cfcomponent>