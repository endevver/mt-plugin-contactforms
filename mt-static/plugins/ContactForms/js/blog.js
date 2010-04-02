function cfShowGreeting() {

    var reg_reqd = false;

    var cf = document['contact_form'];
    if (!cf) return;

    var el = document.getElementById('comment-greeting');
    if (!el)  // legacy MT 4.x element id
        el = document.getElementById('comment-form-external-auth');
    if (!el) return;

    var eid = cf.entry_id;
    var entry_id;
    if (eid) entry_id = eid.value;

    var phrase;
    var u = mtGetUser();

    if ( u && u.is_authenticated ) {
        if ( u.is_banned ) {
            phrase = 'You are not permitted to contact us. (\<a href=\"javas\cript:void(0);\" onclick=\"return mtSignOutOnClick();\"\>sign out\<\/a\>)';
        } else {
            var user_link;
            if ( u.is_author ) {
                user_link = '<a href="http://localhost/~breese/mt/mt-comments.cgi?__mode=edit_profile&return_url=' + encodeURIComponent( location.href );
                user_link += '">' + u.name + '</a>';
            } else {
                // registered user, but not a user with posting rights
                if (u.url)
                    user_link = '<a href="' + u.url + '">' + u.name + '</a>';
                else
                    user_link = u.name;
            }
            // TBD: supplement phrase with userpic if one is available.
            phrase = 'Thanks for signing in, __NAME__. (\<a href=\"javas\cript:void(0)\" onclick=\"return mtSignOutOnClick();\"\>sign out\<\/a\>)';
            phrase = phrase.replace(/__NAME__/, user_link);
        }
    } else {
        if (reg_reqd) {
            phrase = '\<a href=\"javas\cript:void(0)\" onclick=\"return mtSignInOnClick(\'comment-greeting\')\"\>Sign in\<\/a\> to contact us.';
        } else {
            phrase = '\<a href=\"javas\cript:void(0)\" onclick=\"return mtSignInOnClick(\'comment-greeting\')\"\>Sign in\<\/a\> to contact us, or do so anonymously.';
        }
    }
    el.innerHTML = phrase;
}

function cfContactFormOnLoad() {
    var u = mtGetUser();

    // if the user is authenticated, hide the 'anonymous' fields
    // and any captcha input if already shown
    if ( document.getElementById('contact-form')) {
        if ( u && u.is_authenticated ) {
            mtHide('from');
            if (mtCaptchaVisible)
                mtHide('comments-open-captcha');
        } else {

        }

	/*
        if ( u && u.is_banned )
            mtHide('comments-form');
	*/

        // if we're previewing a comment, make sure the captcha
        // field is visible
        if (is_preview)
            mtShowCaptcha();
        else
            cfShowGreeting();

        // populate anonymous comment fields if user is cookied as anonymous
	/*
        var cf = document['comments_form'];
        if (cf) {
            if (u && u.is_anonymous) {
                if (u.email) cf.email.value = u.email;
                if (u.name) cf.author.value = u.name;
                if (u.url) cf.url.value = u.url;
                if (cf.bakecookie)
                    cf.bakecookie.checked = u.name || u.email;
            } else {
                if (u && u.sid && cf.sid)
                    cf.sid.value = u.sid;
            }
            if (cf.post.disabled)
                cf.post.disabled = false;
            if (cf.preview_button.disabled)
                cf.preview_button.disabled = false;
            mtRequestSubmitted = false;
        }
	*/
    }
}
