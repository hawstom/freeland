/*;|
--------------------------------------------------------------------------
---------------------- DCL section ---------------------------------------
--------------------------------------------------------------------------
*/
EditOptions : dialog {
  key = "Title";
  label = "";
  : boxed_column {
    label = "Select a variable to change";
    : list_box {
      key = "list_box1";
      height = 6.27;
      fixed_height = true;
      width = 32.92;
      tabs = "0 20 40";
      fixed_width = true;
    }
    spacer;
    : edit_box {
      key = "edit_box1";
      edit_width = 26.42;
      fixed_width = true;
    }
  }
  spacer;
  ok_cancel;
}
/*
  boxed_row {
	  : button {
	  	
	  	allow_accept = false;
  }
--------------------------------------------------------------------------
---------------------- LSP section ---------------------------------------
--------------------------------------------------------------------------
|;
;;; Sample command to call the EditOptions function
(DEFUN C:EditOptions ()
  ;;Set the initial Options in a global association list
  (COND
    ((NOT *Options*)
     (SETQ *Options* (LIST (CONS "Color" "2") (CONS "Layer" "0")))
    )
  )
  ;;Call the dialog box function
  ;;and set the global options list to what it returns.
  (SETQ *Options* (EditOptions *Options*))
)
;;; Function to show a dialog box that has
;;; a list of variables and their values in a list box
;;; and an initially empty edit box.
;;; When user picks a variable in the list box,
;;; its value is displayed in the edit box.
;;; Then when the edit box is changed, the changed value is stored in the list box.
(DEFUN
   EditOptions (OptionsList  / DCL_ID DialogExitCode ListBox1Contents SELECTEDINDEXINT)
  ;;Make a working copy of the OptionsList
  (SETQ ListBox1Contents OptionsList)
  ;; Load this file as a DCL file
  (SETQ DCL_ID (LOAD_DIALOG "EditOptions.lsp"))
  ;; Initialize the EditOptions dialog from the file.
  (NEW_DIALOG "EditOptions" DCL_ID)
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
    '(LAMBDA (VAR) (ADD_LIST (STRCAT (CAR VAR) "\t" (CDR VAR))))
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
  (ACTION_TILE
    "list_box1"
    "(setq SelectedIndexInt (List1Action $value ListBox1Contents))"
  )
  (ACTION_TILE
    "edit_box1"
    "(setq ListBox1Contents (Edit1Action $value ListBox1Contents SelectedIndexInt))"
  )
  ;; --------------------------------------------------------------------------
  ;;Now finally, with all the above behavior defined,
  ;;display the dialog at last and act as instructed above
  ;;until user exits the dialog.
  ;;When user exits the dialog, the value provided by (done_dialog)
  ;;or the standard buttons is returned.
  ;;Save it so we know whether user accepted or canceled changes.
  (SETQ DialogExitCode (START_DIALOG))
  ;; Unload the DCL file (optional per Help file)
  (UNLOAD_DIALOG DCL_ID)
  (cond
    ;;If user accepted changes, return the ListBox1Contents,
    ((= DialogExitCode 1)
     ListBox1Contents
    )
    ;;Else if user canceled, return original OptionsList
    ((= DialogExitCode 0)
     OptionsList
    )
  )
)
;;; LIST1ACTION
;;; Defines what happens when something in LIST_BOX1 is selected.
;;; Returns the selected index of the list as an integer.
(DEFUN
   LIST1ACTION ($VALUE ListBox1Contents / SELECTEDINDEXINT)
  (SET_TILE
    "edit_box1"
    (CDR (NTH SELECTEDINDEXINT ListBox1Contents))
  )
  SELECTEDINDEXINT
)
;;; EDIT1ACTION
;;; Defines what happens when the EDIT_BOX1 is selected.
;;; Puts the EDIT_BOX1 value with its var into the selected item of the LIST_BOX1 listbox.
;;; Returns the modified list
(DEFUN
   EDIT1ACTION ($VALUE ListBox1Contents SELECTEDINDEXINT / LISTCONTENT
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
;;Return the modified list
(SUBST
(CONS VAR $VALUE)
(ASSOC VAR ListBox1Contents)
ListBox1Contents
)
)
;;Else return the original ListBox1Contents
(ListBox1Contents)
  )  
)
 ;|«Visual LISP© Format Options»
(72 2 40 2 nil "end of " 60 2 2 0 1 nil nil nil T)
;*** DO NOT add text below the comment! ***|;
*/