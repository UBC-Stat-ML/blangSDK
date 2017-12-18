define(function(require, exports, module) {
"use strict";

  var oop = require("../lib/oop");
  var mText = require("./text");
  var mTextHighlightRules = require("./text_highlight_rules");

	var HighlightRules = function() {
		var keywords = "this|it|null|abstract|annotation|boolean|case|catch|char|class|create|def|default|do|double|enum|else|extends|extension|final|finally|float|for|if|implements|import|int|interface|long|new|override|package|private|protected|return|short|static|super|switch|throw|throws|try|typeof|val|var|void|while|FOR|ENDFOR|IF|ENDIF|ELSEIF|BEFORE|AFTER|SEPARATOR";
		this.$rules = {
			"start": [
				{token: "comment", regex: "\\/\\/.*$"},
				{token: "comment", regex: "\\/\\*", next : "comment"},
				{token: "string", regex: '["](?:(?:\\\\.)|(?:[^"\\\\]))*?["]'},
				{token: "string", regex: "['](?:(?:\\\\.)|(?:[^'\\\\]))*?[']"},
				{token: "constant.numeric", regex: "[+-]?\\d+(?:(?:\\.\\d*)?(?:[eE][+-]?\\d+)?)?\\b"},
				{token: "constant.numeric", regex: "0[xX][0-9a-fA-F]+\\b"},
				{token: "lparen", regex: "[\\[({]"},
				{token: "rparen", regex: "[\\])}]"},
				{token: "keyword", regex: "\\b(?:" + keywords + ")\\b"}
			],
			"comment": [
				{token: "comment", regex: ".*?\\*\\/", next : "start"},
				{token: "comment", regex: ".+"}
			]
		};
	};
	oop.inherits(HighlightRules, mTextHighlightRules.TextHighlightRules);
	
	var Mode = function() {
		this.HighlightRules = HighlightRules;
	};
	oop.inherits(Mode, mText.Mode);
	Mode.prototype.$id = "xtend";
	Mode.prototype.getCompletions = function(state, session, pos, prefix) {
		return [];
	}
	
	return {
		Mode: Mode
	};
	
	
});
