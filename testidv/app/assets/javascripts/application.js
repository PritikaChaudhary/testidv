// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require foundation
//= require foundation/foundation.clearing

//=require jquery-fileupload

//= require jquery-ui
//= require_tree .

$(function(){ $(document).foundation(); });

//= require turbolinks


function callAjax(customUrl, divId, formId){
	if(typeof(formId)==='undefined') data = '';
	else data = $('#'+formId).serialize();
	if(typeof(divId)===undefined) divId ='';
	 $('#loan_lenders').html('loading...');
	$.ajax({
		type: 'POST',
		url: customUrl,
		data:data,
		success:function(data){

			$('#'+divId).html(data);
			if(formId=="lender_loans")
			{
				var a_id=divId.replace('loan_lenders','');
				$('#click_'+a_id).hide();
				$('#click_hide_'+a_id).show();
				$("#loan_lenders"+a_id).show();
			}

				},
		error:function(data){
			alert('Something went wrong.');
			
			},
		dataType: 'html',


	});
		
}

$("form").on("keypress", function (e) {
    if (e.keyCode == 13) {
        return false;
    }
});

