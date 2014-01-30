// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require jquery.ui.dialog
//= require_tree .

jQuery(function($){
  $("body").on({
        // When ajaxStart is fired, add 'loading' to body class
        ajaxStart: function() {
            $(this).addClass("loading");
        },
        // When ajaxStop is fired, remove 'loading' from body class
        ajaxStop: function() {
            $(this).removeClass("loading");
        }
    });
});
