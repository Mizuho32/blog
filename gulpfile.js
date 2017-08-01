var gulp = require("gulp");
var bower = require('main-bower-files');
var concat = require("gulp-concat");
var filter = require("gulp-filter");
var rename = require("gulp-rename");
var less = require("gulp-less");


gulp.task("bower", function(){
	var js_filter = filter("*.js");
	gulp.src( bower() )
		.pipe( js_filter )
		.pipe( concat('lib.js') )
		.pipe( gulp.dest('js/lib') )
});

gulp.task('default', ['bower']);
