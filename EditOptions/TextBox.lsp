/*

;;; AutoCAD Wiki AutoLISP code header.  To copy this code, use the 
;;; [Shift] key to highlight starting below the code. Then (in Windows) use the 
;;; [Shift]+[Ctrl]+[Home] key combination to highlight all the way to the 
;;; top of the article.
;;; Then still holding the [Shift] key, use the arrow keys to shrink the top of
;;; the selection down to the beginning of the code.  Then copy and paste.
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; The working version of this software is located at the AutoCAD Wiki.
;;; Please Be Bold in adding clarifying comments and improvements at
;;; http://autocad.wikia.com/wiki/Options_Editor_%28AutoLISP_application%29;|

;;; Revisions
;;;
;;;
;;; 2011-02-16 TGH Released application without setcfg/getcfg or setvar/getvar
;;; 2009-02-07 TGH Released application without setcfg/getcfg or setvar/getvar
--------------------------------------------------------------------------
---------------------- DCL section ---------------------------------------
--------------------------------------------------------------------------
*/
WikiEditOptions : dialog {
  key = "Title";
  label = "";
  : boxed_column {
    label = "Select a variable to change";
    : list_box {
      key = "list_box1";
      height = 6;
      fixed_height = true;
      width = 40;
      fixed_width = true;
    }
    spacer;
    : edit_box {
      key = "edit_box1";
    }
  }
  spacer;
  ok_cancel;
}
/*
--------------------------------------------------------------------------
---------------------- LSP section ---------------------------------------
--------------------------------------------------------------------------
|;
;;; Sample command to call the wiki-EditOptions function
(DEFUN
   C:wiki-EditOptions ()
  ;;Set the initial Options in a global association list
  (COND
    ((NOT *wiki-Options*)
     (SETQ *wiki-Options* (LIST (CONS "Color" "2") (CONS "Layer" "0")))
    )
  )
  ;;Call the dialog box function
  ;;and set the global options list to what it returns.
  (SETQ *wiki-Options* (wiki-EditOptions *wiki-Options*))
)
;;; Function to show a dialog box that has
;;; a list of variables and their values in a list box
;;; and an initially empty edit box.
;;; When user picks a variable in the list box,
;;; its value is displayed in the edit box.
;;; Then when the edit box is changed, the changed value is stored in the list box.
(DEFUN
   wiki-EditOptions (OptionsList / DCL_ID DialogExitCode ListBox1Contents
                SELECTEDINDEXINT
               )
  ;;Make a working copy of the OptionsList
  (SETQ ListBox1Contents OptionsList)
  ;; Load this file as a DCL file
  (SETQ DCL_ID (LOAD_DIALOG "EditOptions.lsp"))
  ;; Initialize the wiki-EditOptions dialog from the file.
  (NEW_DIALOG "WikiEditOptions" DCL_ID)
  ;; --------------------------------------------------------------------------
  ;; SET TILES
  ;; Set the dialog initial conditions
  ;;
  ;;The title
  (SET_TILE "Title" "Options")
  ;;The list box
  ;;Populate the list
  ;;Start_list with the 3 option means we are doing a new list
  (START_LIST "list_box1" 3)
  ;;We add each member of ListBox1Contents to the list_box
  ;;Mapcar runs the lambda function on every member of ListBox1Contents
  (MAPCAR
    ;;The lambda function puts an association group together into a string
    ;;and adds it to the list box list we are building.
    '
     (LAMBDA (VAR) (ADD_LIST (STRCAT (CAR VAR) "\t" (CDR VAR))))
    ListBox1Contents
  )
  ;;End_list finishes building the list box list
  (END_LIST)
  ;; --------------------------------------------------------------------------
  ;; DEFINE ACTIONS
  ;; Define the procedures to be executed for certain ACTIONS that user
  ;; may do while dialog is displayed
  ;; (We don't have a dialog exiting action here, because the default OK button does
  ;; that for us.  Otherwise we would need a (done_dialog) somewhere.)
  ;;
  ;; The (action_tile) for list_box1 says that if something in list_box1 is selected,
  ;; pass its $value (a special variable used in (action_tile) that represents
  ;; the value of the tile, in the case of a single select list_box the string
  ;; representing the index value of the selected row, starting with 0) and the
  ;; ListBox1Contents list to the wiki-EditOptions-LIST1ACTION function
  ;; and set the SelectedIndexInt value to what that function returns.
  (ACTION_TILE
    "list_box1"
    "(setq SelectedIndexInt (wiki-EditOptions-LIST1ACTION $value ListBox1Contents))"
  )
  ;; The (action_tile) for edit_box1 says that if edit_box1 is reported as changed,
  ;; pass its $value (a special variable used in (action_tile)) and other arguments
  ;; to the wiki-EditOptions-EDIT1ACTION function so it can put the edit_box1 value into list_box1,
  ;; and set the ListBoxContents to what the function returns.
  (ACTION_TILE
    "edit_box1"
    "(setq ListBox1Contents (wiki-EditOptions-EDIT1ACTION $value ListBox1Contents SelectedIndexInt))"
  )
  ;; --------------------------------------------------------------------------
  ;;Now finally, with all the above behavior defined,
  ;;display the dialog at last and act as instructed above
  ;;until user exits the dialog.
  ;;When user exits the dialog, the value provided by (done_dialog)
  ;;or the standard buttons is returned.
  ;;Save it so we know whether user accepted or canceled changes.
  (SETQ DialogExitCode (START_DIALOG))
  ;; Unload the DCL file (optional per AutoLISP Reference)
  (UNLOAD_DIALOG DCL_ID)
  (COND
    ;;If user accepted changes, return the ListBox1Contents,
    ((= DialogExitCode 1) ListBox1Contents)
    ;;Else if user canceled, return original OptionsList
    ((= DialogExitCode 0) OptionsList)
  )
)
;;; wiki-EditOptions-LIST1ACTION
;;; Defines what happens when something in LIST_BOX1 is selected.
;;; Returns the selected index of the list as an integer.
(DEFUN
   wiki-EditOptions-LIST1ACTION ($VALUE ListBox1Contents / SELECTEDINDEXINT)
  ;; Turn the single-selection index $value string into an integer.
  (SETQ SELECTEDINDEXINT (READ $VALUE))
  ;; Put the value (right side) of the selected item into edit_box1
  ;; for user to edit
  (SET_TILE
    "edit_box1"
    (CDR (NTH SELECTEDINDEXINT ListBox1Contents))
  )
  ;; Return the selected index value for the edit_box1 action to use
  ;; if it needs to change list_box1
  SELECTEDINDEXINT
)
;;; wiki-EditOptions-EDIT1ACTION
;;; Defines what happens when the EDIT_BOX1 is selected.
;;; Puts the EDIT_BOX1 value with its var into the selected item of the LIST_BOX1 listbox.
;;; Returns the modified list
(DEFUN
   wiki-EditOptions-EDIT1ACTION ($VALUE ListBox1Contents SELECTEDINDEXINT / LISTCONTENT
                SELECTEDINDEXSTRING VAR
               )
  (COND
    ;;If LIST_BOX1 has anything selected,
    (SELECTEDINDEXINT
     ;;Then put together a changed entry
     (SETQ
       VAR         (CAR (NTH SELECTEDINDEXINT ListBox1Contents))
       LISTCONTENT (STRCAT VAR "\t" $VALUE)
     )
     ;;Change the list box tile
     ;;Start_list with the 1 option means we are changing an item
     (START_LIST "list_box1" 1 SELECTEDINDEXINT)
     (ADD_LIST LISTCONTENT)
     (END_LIST)
     ;;Return the modified and up-to-date list of list_box1 contents
     (SUBST
       (CONS VAR $VALUE)
       (ASSOC VAR ListBox1Contents)
       ListBox1Contents
     )
    )
    ;;Else do nothing but return the original ListBox1Contents
    (ListBox1Contents)
  )
)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 2 0 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
*/
