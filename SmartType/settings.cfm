<!---
LICENSE INFORMATION:

Copyright 2010, Adam Tuttle

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
<cfparam name="form.chkDashes" default="false" />
<cfparam name="form.chkEllipses" default="false" />
<cfparam name="form.chkQuotes" default="false" />
<cfparam name="form.chkMultiplication" default="false" />
<cfparam name="form.chkMSWord" default="false" />
<cfparam name="form.chkStupefy" default="false" />
<cfscript>
	//handle settings form post
	if (structKeyExists(form, "submit")){
		local.update = structNew();
		local.update.charTypes = "";

		if (form.chkDashes) { local.update.charTypes = local.update.charTypes & "d"; }
		if (form.chkEllipses) { local.update.charTypes = local.update.charTypes & "e"; }
		if (form.chkQuotes) { local.update.charTypes = local.update.charTypes & "q"; }
		if (form.chkMultiplication) { local.update.charTypes = local.update.charTypes & "x"; }
		if (form.chkMSWord) { local.update.charTypes = local.update.charTypes & "w"; }
		if (form.chkStupefy) { local.update.charTypes = local.update.charTypes & "stupefy"; }

		setSettings(argumentCollection=local.update);
		persistSettings();

		event.data.message.setstatus("success");
		event.data.message.setType("settings");
		event.data.message.settext("SmartType Settings Updated");

		//get current values for display
		initial = local.update.charTypes;
	}else{
		//get current values for display
		initial = getSetting("charTypes");

		form.chkStupefy = findNoCase('stupefy', initial);
		if (form.chkStupefy){
			initial = replaceNoCase(initial, 'stupefy', '');
		}
		form.chkDashes = findNoCase('d', initial);
		form.chkEllipses = findNoCase('e', initial);
		form.chkQuotes = findNoCase('q', initial);
		form.chkMultiplication = findNoCase('x', initial);
		form.chkMSWord = findNoCase('w', initial);
	}
</cfscript>
<style type="text/css">
	.err {
		display: block;
		border: 0;
		border-top: 1px solid #aa0000 !important;
		border-bottom: 1px solid #aa0000 !important;
		background: #ff99cc !important;
		color: #000000 !important; /* #aa0000 */
	}
	.msg {
		display: block;
		border: 0;
		border-top: 1px solid #cccc33;
		border-bottom: 1px solid #cccc33;
		background: #ffff99;
		color: #000000;
		padding: 8px;
	}
</style>

<cfoutput>
<form method="post" action="">
	<fieldset>
		<legend>Character Conversions</legend>
		<p>
			<span class="field">
				<input type="checkbox" id="chkDashes" name="chkDashes" value="true"
					<cfif form.chkDashes>checked="checked"</cfif>
				/>
				<label for="chkDashes">Convert dashes to en- and em-dashes</label>
				<span class="hint">
					A hyphen with a space around it will become an en-dash. Two or three hyphens will become an em-dash.
				</span>
			</span>
		</p>
		<p>
			<span class="field">
				<input type="checkbox" id="chkEllipses" name="chkEllipses" value="true"
					<cfif form.chkEllipses>checked="checked"</cfif>
				/>
				<label for="chkEllipses">Convert multiple periods to ellipses</label>
				<span class="hint">
					A series of three or four dots, with or without spac es in between, will become an ellipsis.
				</span>
			</span>
		</p>
		<p>
			<span class="field">
				<input type="checkbox" id="chkQuotes" name="chkQuotes" value="true"
					<cfif form.chkQuotes>checked="checked"</cfif>
				/>
				<label for="chkQuotes">Convert plain quotes to smart-quotes</label>
				<span class="hint">
					All quote marks and apostrophes will be replaced by their "smart quote" equivalents.
				</span>
			</span>
		</p>
		<p>
			<span class="field">
				<input type="checkbox" id="chkMultiplication" name="chkMultiplication" value="true"
					<cfif form.chkMultiplication>checked="checked"</cfif>
				/>
				<label for="chkMultiplication">Convert an 'x' with digits on either side to a multiplication sign</label>
				<span class="hint">
					An 'x' with digits either side of it, optionally separated by white space, will become a typographic multiplication sign.
				</span>
			</span>
		</p>
		<p>
			<span class="field">
				<input type="checkbox" id="chkMSWord" name="chkMSWord" value="true"
					<cfif form.chkMSWord>checked="checked"</cfif>
				/>
				<label for="chkMSWord">Convert MS Word Entities</label>
				<span class="hint">
					All MS Word-type smart quotes and entities will be converted to plain ASCII equivalents before the main processing is performed.
				</span>
			</span>
		</p>
		<p>
			<span class="field">
				<input type="checkbox" id="chkStupefy" name="chkStupefy" value="true"
					<cfif form.chkStupefy>checked="checked"</cfif>
				/>
				<label for="chkStupefy">Stupefy Entities</label>
				<span class="hint">
					All smart quotes and other HTML entities will be dumbed-down to their ASCII equivalents.
				</span>
			</span>
		</p>
	</fieldset>
	<input type="submit" name="submit" value="Save Changes" />
</form>
</cfoutput>