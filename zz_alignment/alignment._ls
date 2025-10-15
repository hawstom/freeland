;;; MARCH 24, 2006 - ADDED CODE FOR TWO FUNCTIONS FOR DEFINING A POLYLINE FOR ALIGNMENT AND THEN
;;; USING THE TRIM COMMAND TO FIND THE "STATION AND OFFSET" (DAVID WILKINS)
;;;
;;;
;;; ALIGNMENT.LSP
;;; Copyright 2006 David Wilkins and Thomas Gail Haws
;;; This is Free Software licensed under the terms of the GNU General Public License Version 2
;;; You may not put this software into any proprietary package nor distribute it without open source code.
;;
;;; March 7, 2006 - Questioning whether distance or test function comes first.
;;
;;
;;
;;Define Alignment:  This would be a completely separate command   (name could be defalign)
;;
;;	request a name for the alignment name  "Name of Alignment"
;;	Select a polyline  "Select Polyline for Alignment"
;;	User selects a polyline
;;	Once selected the essential polyline data is written to a file for definition and later retrieval
;;	Once selected upon defining, it also becomes the "current alignment"
;;	using the same command as the next command at the end of this routine (setalign)
;;
;;
;;
;;
;;Select Alignment:   (name could be setalign)
;;This would be used if an alignment is already created and the user needs to select an alignment
;;since they just opened the drawing or they were using a different alignment.
;;
;;	request the name of the alignment to be made current  "Set Current Alignment"
;;	the program would read the file that was created using "defalign"
;;
;;notes:
;;
;;The alignment would be understood to go in the direction that the polyline was created.  However, to see
;;the direction of the alignment, another little routine could be added such as "showalign".
;;
;;By using the vertices of the polyline or lwpolyline, it would insert a block that looks like a large arrow
;;pointing in the direction of the polyline.  In order to rotate each block individually it would have to place a 
;;block at each vertex and then rotate to be aligned with the next vertex.  It would only show up at the initiation
;;of the command.  Once a person hits any other key, it would disappear.
;;
;;
;;Station and Offset:  This would allow someone to place a dimension arrow with the station and offset
;;			(perhaps the name could be LBLSTA)
;;
;;
;;	Definition:
;;	The alignment has to be defined or set using the define or setalign command
;;	the user needs to define a selection point to begin the placement/inquiry  (Point X)
;;	if no alignment is set it states "Please define/select alignment first"
;;	if an alignment is set then using trig/math functions it does the following
;;
;;      Does the Test Funtion need to come before the Distance Funtion?
;;
;;
;;	Distance Function:
;;	(for purposes of explanation let's call the first vertex A, the second vertex B, the third vertex C, and so forth to endseq)
;;	the program needs to figure out the distance from A to B and then store as distab
;;	the program nees to digure out the distance from B to C and then store as distbc
;;	the program nees to digure out the distance from C to D and then store as distcd
;;	the program nees to digure out the distance from D to E and then store as distde
;;	and so forth until it finds all distances from each line/curve  (each value nees to be stored for later addition)
;;
;;
;;	Test Function:
;;	starting with the point that the user picks (call it POINT X), it measures the distance from that user point
;;	to the first vertex of the polyline. (distance from X - A)
;;	then it measures the distance from the user point to the second vertex of the polyline (X - B)
;;	If the distance from X-A is greater then X-B, then go to the next two vertices to evaluate
;;	if the distance from X-A is less then or equal to the distance from X-B, then start the Offset funtion.
;;
;;
;;
;;	Offset Function:
;;	Once the program determines the shortest line from X to ??, then it starts this function to determine the distance 
;;	from the point x to the line.  Using trig, it will define the distance and then store as a variable  "off"
;;	also, in order to define the offset distance, the point that was determined to be on the line needs to be saved as a variable "POL"
;;		
;;
;;	
;;	Station Function:
;;	to determine the distance from the first vertex A to point POL, add the distances from AB, BC, CD, etc. until it comes to POL.
;;
;;
;;
;;
;;	
;;	 
;;
;;;FUNCTION NUMBER ONE - SETTING THE ALIGNMENT
;;THIS PROGAM FINDS THE STATION AND OFFSET BASED ON A POLYLINE (PLINETYPE MUST BE SET TO 0) WON'T WORK 
;;WITH LWPOLY
;;THE POLYLINE BEING USED MUST BE ON A LAYER CALLED ALIGNMENT (NOT TRUE AT THE MOMENT)
;;NOTE: A PORTION OF THIS WAS COPIED FROM THE JEFFRYPSANDERS WEB SITE FOR LEARNING HOW TO DO LISP PROGRAMMING 
;;
;;
;;THE IDEA BEHIND THIS PROGRAM IS TO CREATE AN ALIGNMENT USING A POLYLINE.  AT THE MOMENT IT MUST BE A 
;;TRUE POLYLINE
;;NOT A LWPOLYLINE, SO PLINETYPE MUST BE SET TO 0 FOR THIS TO WORK
;;IT WOULD BE NICE TO BE ABLE TO WORK WITH BOTH
;;THE MAIN POINT (NO PUN INTENDED HERE) IS TO GET THE LAST POINT OF THE POLYLINE AND THEN USE THAT 
;;POINT IN THE NEXT
;;FUNCTION OF GETTING THE STATION AND OFFSET. 
;;
;;COMMAND SEQUENCE
;;FIRST - IT WILL ASK FOR YOU TO SELECT THE POLYLINE THAT YOU WANT FOR THE ALIGNMENT
;THEN YOU MUST GIVE IT A STATION VALUE THAT YOU WANT TO USE AT THE BEGINNING OF A POLYLINE
;;
;;
;;
(defun C:setalign()
  (setq en(car(entsel "\n Select a PolyLine to define Aligment: ")))    ;;;--- Get the entity's name
  (setq enlist(entget en))                                              ;;;--- Get the DXF group codes of the entity
  (setq ptList(list))                                                   ;;;--- Create an empty list to hold the points
  (setq en2(entnext en))                                                ;;;--- Get the sub-entities name 
  (setq enlist2(entget en2))                                            ;;;--- Get the dxf group codes of the sub-entity
  (while (not (equal (cdr(assoc 0 (entget(entnext en2))))"SEQEND"))     ;;;--- While the polyline has a next vertice
     (setq en2(entnext en2))                                            ;;;--- Get the next sub-entity
     (setq enlist2(entget en2))                                         ;;;--- Get its dxf group codes
     (if(/= 16 (cdr(assoc 70 enlist2)))                                 ;;;--- Check to make sure it is not a spline reference point
       (setq ptList(append ptList (list (cdr(assoc 10 enlist2)))))      ;;;--- It is a vertex, save the point in a list [ptlist]
     )
  ) 
  (princ)

(command)
(setq ssn1 (getreal "Input Starting Station Number:  "))
(princ)

)                                                                       ;;;--- CLOSE DEFUN


;;
;;
;;
;;FUNCTION TWO - GETTING THE STATION AND OFFSET
;;
;;BEFORE USING THIS ONE, YOU MUST USE THE SETALIGN PORTION
;;
;;THIS PROGAM FINDS THE STATION AND OFFSET BASED ON A POLYLINE
;;
;;COMMAND SEQUENCE
;;FIRST - IT CREATES AN UNDO MARK WHICH IS NEEDED IN ORDER FOR THE PROGRAM TO START AGAIN.  
;;I'M SURE THERE'S ANOTHER WAY OF DOING THIS
;;THAT MAY BE CLEANER.  HOWEVER, THIS DOES SEEM TO WORK
;;SECOND - PICK THE POINT THAT YOU WISH TO STATION
;;THIRD - THEN YOU MUST SELECT THE POLYLINE (ALIGNMENT) WITH THE OSNAP OF PERPENDICULAR SET
;;THE USER MUST SELECT THE POLYLINE IN SUCH A MANNER SO THAT IT IS PERPENDICULAR TO THE POINT 
;;THAT YOU ARE TRYING TO STATION
;FOURTH - THE PROGRAM DRAWS A LINE FROM THE FIRST POINT TO THE LINE WHERE IT IS PERPENDICULAR 
;;AND THEN USES THAT LINE TO 
;TRIM THE POLYLINE.  IN ORDER FOR IT TO TRIM PROPERLY THE POLYLINE'S LAST (X,Y,Z) VALUE IS USED 
;;TO SELECT THE POLYLINE FOR TRIMMING PURPOSES
;;USING THE AREA COMMAND AND THEN PERIMETER IT GETS THE NEWLY TRIMMED POLYLINES LENGTH AND THEN 
;;THE LENGTH OF THE LINE THAT WAS USED
;;FOR TRIMMING.  THE POLYLINE'S LENGTH IS THE STATIONING AND THE LINE'S LENGTH THAT WAS USED FOR 
;;TRIMMING IS THE OFFSET DISTANCE
;;ONCE COMPLETED THE PROGRAM DOES AN UNDO BACK TO THE MARK IN ORDER TO REDRAW THE POLYLINE IN 
;;ORDER TO DO IT AGAIN
;;
;;

(defun C:STOF()

(COMMAND "UNDO" "M")
;(command "-layer" "LO" "*" "UN" "alignment" "")                        ;;;--- WOULD LIKE TO HAVE IT ONLY SELECT THE ENTITY ON AN ALIGNMENT LAYER
(SETQ PT1 (GETPOINT "PICK POINT"))                                      ;;;--- PICKS THE ITEM YOU WISH TO STA
(SETQ PT2 (CAR PT1))                                                    ;;;--- This may be redundant here but defines the x value of PT1
(SETQ PT3 (CADR PT1))                                                   ;;;--- This may be redundant here but defines the y value of PT1
(SETQ PT4 (LIST PT2 PT3))                                               ;;;--- Creates the x,y value for pt1
(COMMAND)
(COMMAND)
(COMMAND)
(COMMAND)
(COMMAND)
(COMMAND "LINE" PT4 "PER" PAUSE "")                                      ;;;--- Draws a line from PT4 to perpendicular to the polyline alignment
(COMMAND "TRIM" "L" "" "E" "E" (last ptlist) "")                         ;;;--- This trims the polyline (alignment) to the line that was created using the last point of the polyline as the selection point

(SETQ EN1 (ENTLAST))                                                     ;;;--- This defines the "trimmed" polyline

;Start the polyline data gathering again on the "trimmed polyline" in order to use the last point of it                                                                  

(setq enlist(entget en1))                                              ;;;--- Get the DXF group codes of the entity
  (setq ptList2(list))                                                   ;;;--- Create an empty list to hold the points
  (setq en2(entnext en1))                                                ;;;--- Get the sub-entities name 
  (setq enlist2(entget en2))                                            ;;;--- Get the dxf group codes of the sub-entity
  (while (not (equal (cdr(assoc 0 (entget(entnext en2))))"SEQEND"))     ;;;--- While the polyline has a next vertice
     (setq en2(entnext en2))                                            ;;;--- Get the next sub-entity
     (setq enlist2(entget en2))                                         ;;;--- Get its dxf group codes
     (if(/= 16 (cdr(assoc 70 enlist2)))                                 ;;;--- Check to make sure it is not a spline reference point
       (setq ptList2(append ptList2 (list (cdr(assoc 10 enlist2)))))      ;;;--- It is a vertex, save the point in a list [ptlist]
     )
  ) 
  (princ)

;(SETQ EN2 (ENTGET EN1))
;SETQ EN3 (cdr(assoc 10 EN2)))
;(SETQ EN4 (cdr(assoc 11 EN2)))
(SETQ OFF1 (DISTANCE PT1 (LAST PTLIST2)))
(PRINC OFF1)
(COMMAND)
;(COMMAND "ERASE" "L" "")
;(COMMAND)
;(COMMAND)
;(SETQ NT1 (ENTLAST))
;(COMMAND)
;(COMMAND)
(COMMAND "AREA" "E" (ENTLAST))
(COMMAND)
(SETQ STA1 (GETVAR "PERIMETER"))
(COMMAND)
(COMMAND)
(COMMAND "UNDO" "B")
(COMMAND)
(COMMAND)
(command "-layer" "U" "*" "")
(COMMAND)
(COMMAND)
(SETQ STA2 (+ SSN1 STA1))
(PRINC "STA: ")(PRINC STA2)(PRINC)
(COMMAND)
(PRINC "OFF: ")(PRINC OFF1)(PRINC)

(COMMAND "LEADER" PT4 PAUSE ""  STA2  OFF1    "")
)                                                     ;CLOSE DEFUN

;;
;;
;;	
;;	
;;