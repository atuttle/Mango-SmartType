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

This file is part of SmartType Mango Blog Plugin.
--->
<cfcomponent extends="BasePlugin">
	<cfset variables.name = "SmartType">
	<cfset variables.id = "com.tuttle.mango.plugins.SmartType">
	<cfset variables.package = "com/tuttle/mango/plugins/SmartType"/>

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="mainManager" type="any" required="true" />
		<cfargument name="preferences" type="any" required="true" />

		<cfset setManager(arguments.mainManager) />
		<cfset setPreferencesManager(arguments.preferences) />

		<!--- set default preferences --->
		<cfset initSettings( charTypes = "dew" )/>
		<cfset persistSettings() />

		<cfreturn this/>
	</cffunction>

	<cffunction name="setup" hint="This is run when a plugin is activated" access="public" output="false" returntype="any">
		<cfreturn "SmartType Activated" />
	</cffunction>

	<cffunction name="unsetup" hint="This is run when a plugin is de-activated" access="public" output="false" returntype="any">
		<cfreturn "SmartType De-activated" />
	</cffunction>

	<cffunction name="upgrade" access="public" output="false" returnType="string">
		<cfreturn "SmartType successfully upgraded." />
	</cffunction>

	<cffunction name="handleEvent" hint="Asynchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfreturn />
	</cffunction>

	<cffunction name="processEvent" hint="Synchronous event handling" access="public" output="false" returntype="any">
		<cfargument name="event" type="any" required="true" />
		<cfset var SmartType = createObject("component", "SmartType").init() />
		<cfset var eventname = arguments.event.getName() />
		<cfset var local = structNew() />

		<cfif eventName EQ "settingsNav">
			<!--- add our settings link --->
			<cfset local.link = structnew() />
			<cfset local.link.owner = "SmartType">
			<cfset local.link.page = "settings" />
			<cfset local.link.title = "SmartType" />
			<cfset local.link.eventName = "SmartType-settings" />
			<cfset arguments.event.addLink(local.link)>

		<cfelseif eventName eq "SmartType-settings">
			<!--- render settings page --->
			<cfsavecontent variable="local.content">
				<cfoutput>
					<cfinclude template="settings.cfm">
				</cfoutput>
			</cfsavecontent>
			<cfset local.data = arguments.event.data />
			<cfset local.data.message.setTitle("SmartType settings") />
			<cfset local.data.message.setData(local.content) />

		<!--- all content events fall into this case --->
		<cfelse>
			<cfset local.settings = getSetting("charTypes") />
			<cfset arguments.event.accessObject.title = unescapeTitle(SmartType.SmartType(arguments.event.accessObject.title, local.settings))/>
			<cfset arguments.event.accessObject.content = SmartType.SmartType(arguments.event.accessObject.content, local.settings)/>

		</cfif>

		<cfreturn arguments.event />
	</cffunction>
	
	<cffunction name="unescapeTitle" access="private" output="false" returntype="string">
		<cfargument name="title" required="true" type="string" />
		<cfset var test = "" />
		<cfset var char = "" />
		
		<cfloop condition="true">
			<cfset test = REFind("&##([0-9]+);", arguments.title, 1, true)>
			<cfif test.len[1] eq 0>
				<cfbreak />
			</cfif>
			<cfset char = mid(arguments.title, test.pos[2], test.len[2]) />
			<cfset arguments.title = Replace(arguments.title, "&###char#;", chr(char), "all") />
		</cfloop>
		
		<cfreturn arguments.title />
	</cffunction>

</cfcomponent>