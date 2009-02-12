<!---
LICENSE INFORMATION:

Copyright 2008 Adam Tuttle
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not 
use this file except in compliance with the License. 

You may obtain a copy of the License at 

	http://www.apache.org/licenses/LICENSE-2.0 
	
Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
CONDITIONS OF ANY KIND, either express or implied. See the License for the 
specific language governing permissions and limitations under the License.

VERSION INFORMATION:

This file is part of SmartType Mango Blog Plugin (0.1).

The version number in parenthesis is in the format versionNumber.subversionRevisionNumber.
--->
<cfcomponent displayname="Handler">
	<cfset variables.name = "SmartType">
	<cfset variables.id = "com.tuttle.mango.plugins.SmartType">
	<cfset variables.package = "com/tuttle/mango/plugins/SmartType"/>
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />
			
		<cfset variables.blogManager = arguments.mainManager />
		<cfset variables.prefs = arguments.preferences />
		
		<cfreturn this/>
	</cffunction>
  
	<cffunction name="getName" access="public" output="false" returntype="string">
		<cfreturn variables.name />
	</cffunction>

	<cffunction name="setName" access="public" output="false" returntype="void">
		<cfargument name="name" type="string" required="true" />
		<cfset variables.name = arguments.name />
		<cfreturn />
	</cffunction>

	<cffunction name="getId" access="public" output="false" returntype="any">
		<cfreturn variables.id />
	</cffunction>

	<cffunction name="setId" access="public" output="false" returntype="void">
		<cfargument name="id" type="any" required="true" />
		<cfset variables.id = arguments.id />
		<cfreturn />
	</cffunction>

	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "SmartType Activated" />
	</cffunction>

	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfreturn "SmartType De-activated" />
	</cffunction>

	<cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfreturn />
	</cffunction>

	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var SmartType = createObject("component", "SmartType").init() />
		
		<cfset arguments.event.accessObject.title = SmartType.SmartType(arguments.event.accessObject.title, "dew")/>
		<cfset arguments.event.accessObject.content = SmartType.SmartType(arguments.event.accessObject.content, "dew")/>
	
		<cfreturn arguments.event />
	</cffunction>  

</cfcomponent>