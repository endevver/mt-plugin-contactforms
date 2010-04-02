# Download

* [Download Contact Forms Beta](INSERT DOWNLOAD URL HERE)

# Plugin Status

*This plugin is currently in BETA. It should not be used in production. Please report bugs here:*

* [http://icanhaz.com/contactforms-support](http://icanhaz.com/contactforms-support)

## Bugs and Known Issues

* Manage Inquiries
  * Display Options: changing date format not supported yet

* Submissions
  * Enforce authentication requirements - not implemented yet

* Features
  * Userpics for replies - considering implementing pending designer
  * Export replies via CSV - not implemented yet

## Postponed Features

* Track the reply to inquiries as well - will not implement in v1.0
* Make it easier to select subscribers to contact forms - will not implement in 1.0
* Replies Feed

# Documentation

## Overview

Contact forms are one of the most common and oldests ways in which
sites have provided their visitors with a way to contact them. They
are preferrable to many because using a form obviates the need to 
disclose an email address. But where many solutions fall short is
that the form itself only automates the sending of an email. They
offer very little customization and are unable to store submitted
form data for searching later.

The Contact Forms plugin for Movable Type provides a comprehensive 
solution for allowing site administrators to manage multiple ways for
their site's visitor's to contact them and ask them questions them
questions via a simple form submission. Contact form submissions
are then stored in the database and tracked to ensure that every 
message is replied to, and to make all responses searchable.

Finally, site administrators are given a simple screen on which 
they can monitor incoming inquiries and respond to them in kind via 
email. 

### Features

* Manage multiple contact forms and design the form elements you
  would like to appear in each.
* Drag-and-drop interface for managing the order of contact form
  field elements.
* Simple interface for managing, monitoring and replying to 
  incoming inquiries.
* Ability to flag inquiries to receive special attention by 
  others, or for later review.
* Quickly view the status of each inquiry through simple icons:
  unread, read and replied to.
* Embed contact forms in a template via a simple template tag, 
  or retrieve from the plugin of the HTML yourself so that you
  drop it into a page, a post, or edit manually. Which ever is
  easier.
* View incoming inquiries and view a specific inquiry using a
  split pane view common to most email applications.

Plus, enjoy using the speedy and responsive plugin because of its
extensive use of javascript and AJAX. That means you can be more
productive because you will spend more time talking to your visitors
and less time waiting for the application to load.

### Pro Features

Users of Movable Type Pro will also have access to the following
features:

* Assign a "Contact Form" custom field to pages and entries.

### Designer Features

Designers can also make special use of this plugin by specifying
in their themes the hooks and information necessary to render 
forms according their unique style and structure. This allows for
theme developers to leverage this plugin to provide a seamless 
experience for their customers as well.

### Developer Features

The Contact Form plugin comes with a standard set of form fields
for rendering and displaying on the published blog for visitors
to fill out. If developers would like to extend the types of form
elements available, they can do so using a simple YAML based API.

## Installation

To install this plugin follow the instructions found here:

    http://tinyurl.com/easy-plugin-install

## Usage

The following describes how to accomplish the most common tasks
with the Contact Form Plugin. 

### How to create a contact form

To create a contact form navigate to "Contact Forms" from the main 
"Manage" menu of Movable Type. From there click the link "Create
Contact Form." A dialog/wizard will pop-up leading you through the
process of creating a form. Here is a brief explanation of each 
of the fields you will be asked to fill out:

* **Form Title** - the name of the contact form.

* **From** - the email address from which all correspondence 
  regarding an inquiry will be sent, mainly the autoresponse sent
  to visitors, and responses sent in reply to an inquiry from with
  the application.

* **Reply To** - the email address to which users will be directed
  to reply to. This will be transmitted as a "Reply-To" header in
  the email. This can be different from the from who the email is
  actually from. For example, the email may be *from* "Support",
  replies should be directed to "Jim."

* **Notification List** - a list of email addresses that should be
  notified whenever a new inquiry is received via a contact form.

* **Status** - allowable values are "open" and "closed." This is
  used to easily turn on and off a contact form. When a status is 
  set to closed, a message can be displayed on any page that embeds
  the form to indicate its status using the `<mt:IsContactFormOpen>`
  tag.

* **Require Authentication** - If authentication is required, then
  visitors will not be able to submit inquires without first 
  authenticating in some way.

* **Auto-Reply Text** - This is the text that will be sent in an 
  email to any user who submits an inquiry via the form. It is a
  way to further personalize your correspondence with visitors.
 
* **Confirmation Text** - This is the text that will be displayed
  to your visitor on your web site immediately following their
  submitting an inquiry.

* **Fields** - This is the list of fields your contact form will
  have. You can add and remove fields to your heart's content. The
  "Subject" and "Body" fields are required and cannot be removed,
  as are the name and email fields for unauthenticated users.

**Adding, Removing and Arranging Contact Form Fields**

One can easily customize their contact form by adding, removing
and even ordering the fields on the screen using a simple
drag-and-drop interface. To edit a form's fields, edit the form
and scroll to the bottom of the page. There you will see a 
list of the form's fields. On the left hand side of each field 
is a small drag handle which can be used to drag and drop the
field up and down the list. 

Click on the red minus icon to delete a field.

To add a field, click "Add Field" and a small form will become
visible prompting your for the field's name or label, the type of
field it is (text, textarea, radio button, pull-down menu, etc)
and any additional options the field may support. When you are 
done defining the field's properties, click the "Add" button 
and your new field will be added to the list of fields
associated with the form. You can then drag and drop the field 
to place it in the position you desire. 

When you are finished, save the form and your fields will be
updated, added or removed accordingly.

You may need to republish pages and templates that utilize the 
form in order for your changes to be reflected properly.

### How to embed a contact form on your web site

There are two primary ways in which a form can be placed on a
web site:

* Adding the Form's HTML directly to a page or entry

* Inserting the form via a template tag used within a template
  on your web site.

**Adding a Form via HTML Directly**

Some people may want to add a contact form directly to a page
manually without having to worry about editing a template. To do 
do so, visit the "Manage Contact Forms" screen found via the
"Manage" menu. A link can be found associated with each form 
listed there entitled "Show HTML." Click the link corresponding
to the form you want to embed.

A dialog will then appear showing the contact form's HTML. Copy
this HTML to your clipboard. Then edit the entry, page or 
template you want to add the contact form to and paste your
clipboard's content into place.

Save and republish the page/entry/template and you are done.

One down-side of this approach is that any changes made to the
form subsequent to pasting into the page will not be reflected.
You will be required to repaste the form's content into each of
the respective pages whenever the form is modified.

To avoid this inconvenience, consider inserting the form via
a template tag discussed below.

**Adding a Form via a Template Tag**

The following template tag can be used to render a contact 
form on your website:

    <$mt:ContactForm id="$id"$>

When a template is rendered, the tag above will be replaced
with the complete HTML associated with contact form with the
given ID. The HTML and structure of the form itself is derived
from the Global or Local System Template conveniently entitled 
"Contact Form." 

### How to customize the HTML of a contact form

The best way and recommended way for that matter to customize
your contact forms' HTML is via the System Template entitled
"Contact Form." If you are using a theme that supports the 
contact form plugin explicitly then you will find a blog-level
system template with this name to edit. Otherwise, you can
find a global system template with this name. 

The default contact form template illustrates the best way to 
structure the template. That is to say that the template 
consists of three primary components in this sequence:

* a header - which includes the form tag and hidden form
  elements that makes the form work.
* a loop that iterates over and displays each field according
  to its type
* a footer - which includes the form's buttons

The header and footer should hardly be messed with. What it
is most essential in customizing the form's look and feel is
the loop that is responsible for rendering a pull down menu,
or a text box, or textarea, etc.

For more information, consult the template tag reference
found later in this document.

### How to track incoming inquiries

To monitor incoming inquiries, or contact form submission, 
navigate to the "Manage Inquiries" screen via the "Manage" 
menu in Movable Type's main navigation. 

From there you can see all recent inquiries and their status
(read, unread, etc). You can click on an inquiry to read it,
and from there reply to directly to the inquiry, flag it, 
or delete it.

### How to reply to an inquiry from within Movable Type

To reply to an inquiry, click on the inquiry's subject to
read the inquiry in the bottom pane. In that pane you will
find a "reply" button. Clicking it will open a small dialog
into which you can type your response. When you are done,
click the "Send" button and the person who submitted the
inquiry will be sent your response via email.

### How to flag an inquiry

To flag or unflag an inquiry, click on the inquiry's subject 
to view the inquiry in the bottom pane. In that pane you will
find a "flag" or "unflag" button depending on the inquiry's
current status. Clicking that button will then toggle the 
inquiry's flagged state.

### How to export a list of inquiries in CSV format

Users may wish to export a list of all of the inquiries
submitted via a contact form. This can be useful for people
harvesting a list of email addresses of people who have 
opted in for a newsletter for example. To export a list of 
replies 

## Template Tags

A complete reference to the contact form plugin's template tags can
be found at the following URL:

TBD

## Designer Guide

Designers can register their own contact form template for rendering
forms according to their template set's own unique structure and
style. To do so a design will need to do two things:

1. Register their template in their theme's config.yaml as a system
   template

2. Construct their template using the template tags supported by the
   Contact Form plugin

### Registering Your Contact Form

To register your contact form you will need to make the following
addition to your template set/theme plugin's config.yaml:

    name: My Theme
    description: This is a theme to install for Movable Type
    version: 1.1
    template_sets:
      my_theme:
        base_path: templates
        label: 'My Theme (Blue)'
        templates:
          system:
            contact_form:
              label: Contact Form
        
The operative component being:

    templates:
      system:
        contact_form:
          label: Contact Form

You will then need to create a file called `contact_form.mtml` and
place it among your theme's other templates. Inside this file you 
would place the contents used to render the form as you see fit.

This template will then be used whenever the `<mt:ContactFormHTML>` 
template tag is invoked. If your theme does not install this template,
then the plugin will fall back and use the global system template 
called "Contact Form."

This method allows you to provide a custom design for your contact
form as you choose to do so. If not, you can always rely on the default
HTML produced by the plugin and style your form with CSS accordinginly.

### Building Your Contact Form Template

The best way to customize your Contact Form template for a blog using
a template set without a contact form template already defined, do
the following:

1. Go to Preferences > Plugin
2. Expand the "Contact Forms" plugin on the plugin listing page
3. Click the "Settings" tab
4. Click "Install Contact Form System Template"
5. Navigate to Design > Templates
6. Scroll down to the Contact Form template listed under "System
   Templates."

Done.

#### Sample Template

    <mt:IfContactFormOpen>
    <script type="text/javascript" src="<mt:StaticWebPath>plugins/ContactForms/js/blog.js"></script>
    <div id="contactform">
      <div id="comment-greeting"></div>
      <form method="post" action="<mt:CGIPath><mt:AdminScript>" id="contact-form" name="contact_form">
        <input type="hidden" name="__mode" value="cf.submit_reply" />
        <input type="hidden" name="blog_id" value="<mt:BlogID>" />
        <input type="hidden" name="form_id" value="<mt:ContactFormID>" />
        <fieldset id="from">
          <div id="field-from-name">  
            <label for="name">Name</label>  
            <input id="name" name="name" size="30" value="" />  
          </div> 
          <div id="field-from-email">  
            <label for="email">Email</label>  
            <input id="email" name="email" size="30" value="" />  
          </div> 
        </fieldset>
        <fieldset id="fields">
    <mt:ContactFormFields>
    <mt:if tag="ContactFormFieldType" eq="text">
        <div id="field-<mt:ContactFormFieldLabel dirify="1">">
          <label for="<mt:ContactFormFieldLabel dirify="1">"><mt:ContactFormFieldLabel></label>
          <input id="<mt:ContactFormFieldLabel dirify="1">" name="<mt:ContactFormFieldLabel dirify="1">" size="30" value="" />
        </div>
    <mt:else tag="ContactFormFieldType" eq="textarea">
        <div id="field-<mt:ContactFormFieldLabel dirify="1">">
          <label for="<mt:ContactFormFieldLabel dirify="1">"><mt:ContactFormFieldLabel></label>
          <textarea id="<mt:ContactFormFieldLabel dirify="1">" name="<mt:ContactFormFieldLabel dirify="1">" rows="15" cols="50"></textarea>
        </div>
    <mt:else tag="ContactFormFieldType" eq="checkbox">
        <div id="field-<mt:ContactFormFieldLabel dirify="1">">
          <input type="checkbox" id="<mt:ContactFormFieldLabel dirify="1">" name="<mt:ContactFormFieldLabel dirify="1">" value="1" />
          <label for="<mt:ContactFormFieldLabel dirify="1">"><mt:ContactFormFieldLabel></label>
        </div>
    <mt:else tag="ContactFormFieldType" eq="select">
        <div id="field-<mt:ContactFormFieldLabel dirify="1">">
          <label for="<mt:ContactFormFieldLabel dirify="1">"><mt:ContactFormFieldLabel></label>
          <select id="<mt:ContactFormFieldLabel dirify="1">" name="<mt:ContactFormFieldLabel dirify="1">">
    <mt:ContactFormFieldValueLoop>
            <option><mt:ContactFormFieldValue></option>
    </mt:ContactFormFieldValueLoop>
          </select>
        </div>
    <mt:else tag="ContactFormFieldType" eq="radio">
        <div id="field-<mt:ContactFormFieldLabel dirify="1">">
          <label><mt:ContactFormFieldLabel></label>
    <mt:ContactFormFieldValueLoop>
          <label><input type="radio" name="<mt:ContactFormFieldValue dirify="1">" value="<mt:ContactFormFieldValue dirify="1">" /> <mt:ContactFormFieldValue></label>
    </mt:ContactFormFieldValueLoop>
    </mt:if>
        </fieldset>
    </mt:ContactFormFields>
        <div id="comments-open-captcha"></div>
        <div id="contactform-footer">
          <input type="submit" accesskey="s" name="post" id="contactform-submit" value="Submit" />
        </div>
      </form>
    </div>
    <script type="text/javascript">
    cfContactFormOnLoad();
    </script>
    <mt:else>
    Out apologies, but this contact form is no longer active or available.
    </mt:IfContactFormOpen>

## Developer Guide
