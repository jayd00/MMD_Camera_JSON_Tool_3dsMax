-- by J16D
-- MMD Camera to JSON Cleo Redux GTASA
-- Latest update: 26.12.2025
--
-- V5.4 - Fixed Rotations
------------------------------------------------------------------------------------------------------------
global gtaCameraDance

try(destroyDialog gtaCameraDance.uiInst) catch()
------------------------------------------------------------------------------------------------------------
-- this is needed to be able to setup UTF-8
fn patchCharacterEncoding =
(
	local legacySettings = getIniSetting (getMAXIniFile()) "File Language Options" "LegacyFilesCanBeStoredUsingUTF8"
	if legacySettings == "1" do (
		setIniSetting (getMAXIniFile()) "File Language Options" "LegacyFilesCanBeStoredUsingUTF8" "0"
	)
)
patchCharacterEncoding()
------------------------------------------------------------------------------------------------------------
struct gtaCam_struct
(
	d_width=230,
	d_height=395,
	uiInst = undefined,
	------------------------------------------------------------------------
	fn ui =
	(
		rollout UICameraDanceDialog "MMD Camera JSON Tool"
		(
			local parentCamera = undefined
			local selectedCamera = undefined
			local targetCam = undefined
			local targetObj = undefined
			local SetMatrix
			local btnWidth = 100
			local btnPosY = 65
			----------------------------------------------------------------------------------------------------
			dotNetControl lblTitle "System.Windows.Forms.Label" width:(gtaCameraDance.d_width-20) height:30 pos:[10,10]
			----------------------------------------------------------------------------------------------------
			dotNetControl lblTemp1 "System.Windows.Forms.Label" width:(gtaCameraDance.d_width-20) height:13 pos:[10,35]
			dotNetControl lblCam "System.Windows.Forms.Label" width:btnWidth height:25 pos:[40,(btnPosY-15)]
			imgTag itIcCamera "imgtag" pos:[15,(btnPosY-15)] iconName:@"CommandPanel\Motion\BipedRollout\CopyAndPaste\ShowSnapshot" iconSize:[24,24] applyUIScaling:true
			dotNetControl dn_lblCam "System.Windows.Forms.Label" width:155 height:20 pos:[20,(btnPosY+13)]
			button btnDelCam "D" width:20 height:20 iconName:@"CivilView\DeselectStrings" iconSize:[16,16] pos:[180, (btnPosY+12)] 
			button btnPickCam "P" width:20 height:20 iconName:@"ColorPicker\EyeDropper" iconSize:[16,16] pos:[200, (btnPosY+12)]
			dotNetControl lblTemp0 "System.Windows.Forms.Label" width:(gtaCameraDance.d_width-20) height:13 pos:[10,(btnPosY+35)]
			----------------------------------------------------------------------------------------------------
			imgTag itIcRot "imgtag" iconName:@"Common\Settings" iconSize:[16,16] applyUIScaling:true pos:[20,(btnPosY+55)]
			dotNetControl lblSett "System.Windows.Forms.Label" width:150 height:25 pos:[45,(btnPosY+51)]
			spinner spnRotX "X:" range:[0, 360, 0] type:#float fieldWidth:40 align:#left
			spinner spnRotY "Y:" range:[0, 360, 0] type:#float fieldWidth:40 align:#left
			spinner spnRotZ "Z:" range:[0, 360, 180] type:#float fieldWidth:40 align:#left
			dotNetControl lblInfoSett "System.Windows.Forms.Label" width:135 height:40 pos:[85,(btnPosY+70)]
			button btnApplyRot "Execute" width:135 height:30 enabled:false pos:[85,(btnPosY+110)]
			
			dotNetControl lblTemp3 "System.Windows.Forms.Label" width:(gtaCameraDance.d_width-20) height:13 pos:[10,(btnPosY+140)]
			----------------------------------------------------------------------------------------------------
			spinner spnFovOffset "FOV Offset:" range:[-180, 180, 0] type:#float fieldWidth:50 align:#left pos:[15,(btnPosY+166)]
			button btnApplyFov "Apply" width:80 height:30 enabled:false pos:[140,(btnPosY+160)]
			
			dotNetControl lblTemp4 "System.Windows.Forms.Label" width:(gtaCameraDance.d_width-20) height:13 pos:[10,(btnPosY+190)]
			----------------------------------------------------------------------------------------------------
			imgTag itIcPaper "imgtag" iconName:@"Common\Copy" iconSize:[16,16] applyUIScaling:true pos:[20,(btnPosY+210)]
			dotNetControl lblImpExp "System.Windows.Forms.Label" width:140 height:25 pos:[45,(btnPosY+208)]
			
			button btnImport "Import" width:90 height:30 pos:[40,(btnPosY+240)]
			button btnExport "Export" width:90 height:30 enabled:false pos:[130,(btnPosY+240)]
			button btnCFreeToTarget "F->T" width:30 height:30 pos:[10,(btnPosY+240)] iconName:@"CommandPanel\Motion\BipedRollout\MotionCapture\ConvertFromBuffer" iconSize:[16,16] tooltip:"Converts Free Camera Animation into a Target Camera"
			
			dotNetControl lblTemp2 "System.Windows.Forms.Label" width:(gtaCameraDance.d_width-20) height:13 pos:[10,(btnPosY+275)]
			----------------------------------------------------------------------------------------------------
			dotNetControl lblby "System.Windows.Forms.Label" width:150 height:25 align:#center
			
			------------------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------------------
			fn dotNet_labelSetup dnLabel str col align:#left =
			(
				dnLabel.Text = str
				dnLabel.BackColor= (dotNetClass "System.Drawing.Color").fromArgb col col col
				dnLabel.ForeColor= (dotNetClass "System.Drawing.Color").silver
				case align of
				(
					#left: ( dnLabel.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleLeft )
					#right: ( dnLabel.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleRight )
					#center: ( dnLabel.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleCenter )
					default: ( dnLabel.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleLeft )
				)
				dnLabel.Padding = (dotNetObject "System.Windows.Forms.Padding" 5 0 0 0)
			)
			
			fn cleanDialog =
			(
				clearSelection()
				selectedCamera = undefined
				parentCamera = undefined
				dn_lblCam.Text = ""
				btnExport.enabled = false
				btnApplyRot.enabled = false
				btnApplyFov.enabled = false				
			)
			
			fn buildCam CameraName typeCam:#target =
			(
				local cam = freecamera name:CameraName
				cam.position = [-5.0, 0.0, 0.0]
				cam.type = typeCam
				select cam
				if typeCam == #target do 
				( 
					cam.Target.name = (cam.name+".Target")
					cam.target.position = [-0.324,0.0,0.0]
					cam.clipManually = true
					cam.targetDistance = 80.0
				)
				cam.fovType = 1
				cam.nearrange = 0.0
				cam.farrange = 15.0
				cam.nearclip = 0.01
				cam.farclip = 15.0
				cam.fov = 45.0
				cam
			)

			fn formatTo3Decimals val = ( formattedPrint val format:".3f" )
			
			fn frameToTime frame =
			(
				local timeValue = (frame as float) / frameRate
				timeValue
			)
			
			fn timeToFrame timeVal =
			(
				local frame = timeVal * frameRate
				frame as integer
			)
			
			fn getKeysFromController ctrl =
			(
				local keyFrames = #()
				try
				(
					if ctrl != undefined then
					(
						if classOf ctrl == Position_XYZ then
						(
							if ctrl.x_position.controller.keys != undefined then
							(
								for k in ctrl.x_position.controller.keys do
								(
									appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
								)
							)
							if ctrl.y_position.controller.keys != undefined then
							(
								for k in ctrl.y_position.controller.keys do
								(
									appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
								)
							)
							if ctrl.z_position.controller.keys != undefined then
							(
								for k in ctrl.z_position.controller.keys do
								(
									appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
								)
							)
						)
						else if classOf ctrl == Euler_XYZ then
						(
							if ctrl.x_rotation.controller.keys != undefined then
							(
								for k in ctrl.x_rotation.controller.keys do
								(
									appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
								)
							)
							if ctrl.y_rotation.controller.keys != undefined then
							(
								for k in ctrl.y_rotation.controller.keys do
								(
									appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
								)
							)
							if ctrl.z_rotation.controller.keys != undefined then
							(
								for k in ctrl.z_rotation.controller.keys do
								(
									appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
								)
							)
						)
						else if ctrl.keys != undefined then
						(
							for k in ctrl.keys do
							(
								appendIfUnique keyFrames ((k.time / ticksPerFrame) as integer)
							)
						)
					)
				) catch()
				keyFrames
			)
			
			fn getAnimatedFrames camObj =
			(
				local frames = #()
				local posKeys = getKeysFromController camObj.pos.controller
				for f in posKeys do ( appendIfUnique frames f )
				
				if camObj.type == #target and camObj.target != undefined then
				(
					local targetPosKeys = getKeysFromController camObj.target.pos.controller
					for f in targetPosKeys do ( appendIfUnique frames f )
				)
				
				if camObj.controller != undefined then
				(
					local rollKeys = getKeysFromController camObj.controller
					for f in rollKeys do ( appendIfUnique frames f )
				)
				local fovKeys = getKeysFromController camObj.fov.controller
				for f in fovKeys do ( appendIfUnique frames f )
				sort frames
				frames
			)
			
			fn getFCAnimatedFrames camObj =
			(
				local frames = #()
				local posKeys = getKeysFromController camObj.pos.controller
				for f in posKeys do ( appendIfUnique frames f )
				
				local rotKeys = getKeysFromController camObj.rotation.controller
				for f in rotKeys do ( appendIfUnique frames f )
				
				local fovKeys = getKeysFromController camObj.fov.controller
				for f in fovKeys do ( appendIfUnique frames f )
				
				if frames.count == 0 then
				(
					local startF = (animationRange.start / ticksPerFrame) as integer
					local endF = (animationRange.end / ticksPerFrame) as integer
					frames = #(startF, endF)
				)
				sort frames
				frames
			)
			
			fn cleanupBakedKeys cam originalFrames startF endF =
			(
				if cam == undefined or originalFrames.count == 0 then return()
				format "Cleaning up baked keys...\n"
				
				local posCtrl = cam.position.controller
				local targetPosCtrl = if cam.type == #target then cam.target.position.controller else undefined
				
				local originalValues = #()
				for f in originalFrames do
				(
					at time f
					(
						local camPos = in coordsys world cam.position
						local targetPos = if cam.type == #target then (in coordsys world cam.target.position) else [0,0,0]
						local rollVal = if cam.controller != undefined then cam.controller.roll_angle else 0.0
						append originalValues #(f, camPos, targetPos, rollVal)
					)
				)
				
				if classOf posCtrl == Position_XYZ then
				(
					deleteKeys posCtrl.x_position.controller #allKeys
					deleteKeys posCtrl.y_position.controller #allKeys
					deleteKeys posCtrl.z_position.controller #allKeys
				)
				else
				(
					deleteKeys posCtrl #allKeys
				)
				
				if targetPosCtrl != undefined then
				(
					if classOf targetPosCtrl == Position_XYZ then
					(
						deleteKeys targetPosCtrl.x_position.controller #allKeys
						deleteKeys targetPosCtrl.y_position.controller #allKeys
						deleteKeys targetPosCtrl.z_position.controller #allKeys
					)
					else
					(
						deleteKeys targetPosCtrl #allKeys
					)
				)
				
				if cam.controller != undefined then
				(
					deleteKeys cam.controller #allKeys
				)
				
				for val in originalValues do
				(
					at time val[1]
					(
						with animate on
						(
							in coordsys world cam.position = val[2]
							if cam.type == #target then
							(
								in coordsys world cam.target.position = val[3]
							)
							if cam.controller != undefined then
							(
								cam.controller.roll_angle = val[4]
							)
						)
					)
				)
				format "Cleanup completed!\n"
			)			
			
			fn convertCamera cam targetDistance:1.0 =
			(
				if cam == undefined then
				(
					messageBox "No camera selected!" title:"Error"
					return()
				)
				
				if classOf cam != Freecamera then
				(
					messageBox "Camera must be a Free Camera!" title:"Error"
					return()
				)
				local animFrames = getFCAnimatedFrames cam
				if animFrames.count == 0 then
				(
					animFrames = #((animationRange.start / ticksPerFrame) as integer)
				)
				
				local startFrame = animFrames[1]
				local endFrame = animFrames[animFrames.count]
				-----------------
				local newCamName = cam.name + "_NEW"
				local tCam = targetCamera name:newCamName target:(targetObject())
				tCam.Target.name = (tCam.name+".Target")
				
				tCam.fov = cam.fov
				tCam.nearclip = cam.nearclip
				tCam.farclip = cam.farclip
				tCam.nearrange = cam.nearrange
				tCam.farrange = cam.farrange
				------------
				for f = startFrame to endFrame do
				(
					at time f
					(
						local camPos = cam.transform.position
						local viewDir = normalize (cam.transform.row3 * -1)
						
						local targetPos = camPos + (viewDir * targetDistance)
						
						with animate on
						(
							tCam.pos = camPos
							tCam.target.pos = targetPos
						)
					)
				)
				
				local fovKeys = getKeysFromController cam.fov.controller
				for f in fovKeys do
				(
					at time f
					(
						with animate on
						(
							tCam.fov = cam.fov
						)
					)
				)
				
				for f = startFrame to endFrame do
				(
					at time f
					(
						with animate on
						(
							local upVector = normalize cam.transform.row2
							local viewDir = normalize (cam.transform.row3 * -1)
							local rightVector = normalize (cross viewDir upVector)
							
							local targetDir = normalize (tCam.target.pos - tCam.pos)
							local projUp = normalize (upVector - (dot upVector targetDir) * targetDir)
							
							local worldUp = [0,0,1]
							local refRight = normalize (cross targetDir worldUp)
							local refUp = normalize (cross refRight targetDir)
							
							local rollAngle = atan2 (dot projUp refRight) (dot projUp refUp)
							
							tCam.controller.roll_angle = rollAngle*-1
						)
					)
				)				
				cleanupBakedKeys tCam animFrames startFrame endFrame
				
				
				clearSelection()
				select cam 
				delete $
				select tCam
				cleanDialog()
			)
			
			fn exportCameraJSON camObj filePath =
			(
				if camObj.type != #target do
				(
					format "Incorrect Camera Type! Must be Target Camera.\n"
					return()
				)
				sliderTime = 0
				local frames = getAnimatedFrames camObj
				if frames.count == 0 then
				(
					format "No animation keys found on camera!\n"
					return()
				)
				progressStart "Exporting camera animation..."
				-----------------------------------------------------------------
				local jsonData = "[\n"
				local firstEntry = true
				local totalFrames = frames.count
				
				for i = 1 to totalFrames do
				(
					local f = frames[i]
					if mod i 10 == 0 or i == totalFrames then
					(
						local progress = (i as float / totalFrames) * 100.0
						progressUpdate progress
						progressText = "Exporting frame " + i as string + " of " + totalFrames as string
					)
					
					if not firstEntry then ( jsonData += ",\n" )
					else ( firstEntry = false )
					
					local t = frameToTime f
					local x, y, z, tx, ty, tz, rollVal, fovVal
					
					in coordsys world x = at time f camObj.position.controller.x_position 
					in coordsys world y = at time f camObj.position.controller.y_position
					in coordsys world z = at time f camObj.position.controller.z_position

					in coordsys world tx = at time f camObj.target.position.controller.x_position
					in coordsys world ty = at time f camObj.target.position.controller.y_position
					in coordsys world tz = at time f camObj.target.position.controller.z_position

					-- Export roll with sign inversion to match Blender import
					in coordsys world rollVal = (at time f camObj.controller.roll_angle) * -1.0
					fovVal = at time f camObj.fov
					-----------------------------------------------------------
					jsonData += "  { "
					jsonData += "\"t\": " + (formatTo3Decimals t) + ", "
					jsonData += "\"x\": " + (formatTo3Decimals x) + ", "
					jsonData += "\"y\": " + (formatTo3Decimals y) + ", "
					jsonData += "\"z\": " + (formatTo3Decimals z) + ", "
					jsonData += "\"tx\": " + (formatTo3Decimals tx) + ", "
					jsonData += "\"ty\": " + (formatTo3Decimals ty) + ", "
					jsonData += "\"tz\": " + (formatTo3Decimals tz) + ", "
					jsonData += "\"roll\": " + (formatTo3Decimals rollVal) + ", "
					jsonData += "\"fov\": " + (formatTo3Decimals fovVal) + " }"						
				)
				jsonData += "\n]"
				progressEnd()
				
				local outFile = createFile filePath
				if outFile != undefined then
				(
					format jsonData to:outFile
					close outFile
					format ("Successfully exported " + frames.count as string + " keyframes to:\n" + filePath + "\n")
				)
				else
				(
					format "Error creating file!\n"
				)
				cleanDialog()
			)
			
			fn importCameraJSON filePath =
			(
				progressStart "Reading JSON file..."
				
				local inFile = openFile filePath
				if inFile == undefined then
				(
					progressEnd()
					format "Error opening file!\n"
					return()
				)
				
				local jsonText = ""
				while not eof inFile do ( jsonText += readLine inFile + "\n" )
				close inFile
				
				progressUpdate 20
				progressText = "Parsing JSON data..."
				
				local entries = #()
				local lines = filterString jsonText "\n\r"
				
				for line in lines do
				(
					if findString line "\"t\":" != undefined then
					(
						local entry = #()
						local parts = filterString line ",{}"
						
						for part in parts do
						(
							if findString part "\"t\":" != undefined then
							(
								local val = substituteString part "\"t\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"x\":" != undefined then
							(
								local val = substituteString part "\"x\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"y\":" != undefined then
							(
								local val = substituteString part "\"y\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"z\":" != undefined then
							(
								local val = substituteString part "\"z\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"tx\":" != undefined then
							(
								local val = substituteString part "\"tx\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"ty\":" != undefined then
							(
								local val = substituteString part "\"ty\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"tz\":" != undefined then
							(
								local val = substituteString part "\"tz\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"roll\":" != undefined then
							(
								local val = substituteString part "\"roll\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
							else if findString part "\"fov\":" != undefined then
							(
								local val = substituteString part "\"fov\":" ""
								val = substituteString val " " ""
								append entry (val as float)
							)
						)
						if entry.count == 9 then ( append entries entry )
					)
				)
				
				if entries.count == 0 then
				(
					progressEnd()
					format "No valid data found in JSON file!\n"
					return()
				)
				progressUpdate 40
				progressText = "Creating camera..."
				
				local camName = "MMD_Camera"
				local newCam = getNodeByName camName
				if newCam == undefined then 
				(
					newCam = buildCam camName typeCam:#target
				)
				-----------------------------------------------------------------
				-- Clear existing animation
				deleteKeys newCam.pos.controller
				deleteKeys newCam.target.pos.controller
				
				setCommandPanelTaskMode mode:#motion
				
				progressUpdate 50
				progressText = "Applying animation..."
				
				local totalEntries = entries.count
				
 				-- Animate camera with keys
				for i = 1 to totalEntries do
				(
					local entry = entries[i]
					local t = entry[1]
					local frame = timeToFrame t
					
					if mod i 10 == 0 or i == totalEntries then
					(
						local progress = 50 + ((i as float / totalEntries) * 50.0)
						progressUpdate progress
						progressText = "Importing keyframe " + i as string + " of " + totalEntries as string
					)
					
					with animate on
					(
						at time frame newCam.position.controller.value = [entry[2], entry[3], entry[4]]
						at time frame newCam.target.position.controller.value = [entry[5], entry[6], entry[7]]
						-- 3ds Max camera roll is inverted compared to Blender's Y rotation
						at time frame newCam.controller.roll_angle = entry[8] * -1.0
						at time frame newCam.fov = entry[9]
					)
				)
				local totalKeyFrames = getAnimatedFrames newCam
				local lastFrame = totalKeyFrames[totalKeyFrames.count]
				animationRange = interval 0 lastFrame
				progressEnd()
				sliderTime = 0
				----------------------
				select newCam
				selectedCamera = selection[1]
				dn_lblCam.Text = selectedCamera.name
				parentCamera = selectedCamera.parent
				btnExport.enabled = true
				btnApplyRot.enabled = true
				btnApplyFov.enabled = true
				----------------------
				format ("Successfully imported " + entries.count as string + " keyframes! - Created: " + camName +"\n")
				setArrowCursor()
				enableSceneRedraw()
				CompleteRedraw()
				gc()
			)
			
			fn bakeAnimation cam startF endF =
			(
				if cam == undefined then return()
				format "Baking animation from frame % to %...\n" startF endF
				for f = startF to endF do
				(
					at time f
					(
						with animate on
						(
							in coordsys world tempPos = cam.position
							in coordsys world cam.position = tempPos
							
							if cam.type == #target then
							(
								in coordsys world tempTargetPos = cam.target.position
								in coordsys world cam.target.position = tempTargetPos
							)
							
							if cam.controller != undefined then
							(
								local tempRoll = cam.controller.roll_angle
								cam.controller.roll_angle = tempRoll
							)
						)
					)
				)
				format "Bake completed!\n"
			)
			
			-----------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------
			-- Function to get all keyframes from an object
			fn getKeyFrames obj =
			(
				local keyTimes = #()
				if obj.position.controller != undefined then
				(
					for i = 1 to obj.position.controller.keys.count do
					(
						appendIfUnique keyTimes obj.position.controller.keys[i].time
					)
				)
				if obj.rotation.controller != undefined then
				(
					for i = 1 to obj.rotation.controller.keys.count do
					(
						appendIfUnique keyTimes obj.rotation.controller.keys[i].time
					)
				)
				sort keyTimes
				return keyTimes
			)
			
			-- Function to store camera data at dummy keyframes
			fn storeCameraData dummyObj camObj dummyKeys =
			(
				local camPositions = #()
				local camFOVs = #()
				for t in dummyKeys do
				(
					at time t
					(
						append camPositions camObj.transform.position
						append camFOVs camObj.fov
					)
				)
				return #(camPositions, camFOVs)
			)
			
			-- Function to synchronize keyframes between dummy and camera
			fn syncKeyframes dummyObj camObj =
			(
				local dummyKeys = getKeyFrames dummyObj
				local camData = storeCameraData dummyObj camObj dummyKeys
				local camPositions = camData[1]
				local camFOVs = camData[2]
				
				if camObj.position.controller != undefined then
				(
					while camObj.position.controller.keys.count > 0 do
						deleteKey camObj.position.controller 1
				)
				if camObj.rotation.controller != undefined then
				(
					while camObj.rotation.controller.keys.count > 0 do
						deleteKey camObj.rotation.controller 1
				)
				if camObj.fov.controller != undefined then
				(
					while camObj.fov.controller.keys.count > 0 do
						deleteKey camObj.fov.controller 1
				)
				for i = 1 to dummyKeys.count do
				(
					at time dummyKeys[i]
					(
						with animate on
						(
							camObj.pos = camPositions[i]
							camObj.rotation = camObj.rotation
							camObj.fov = camFOVs[i]
						)
					)
				)
				return #(dummyKeys, camPositions, camFOVs)
			)			
			
			-- Function to rotate entire animation
			fn rotateAnimation cam tgt rotX rotY rotZ =
			(
				local rotMatrix = rotateXMatrix rotX * rotateYMatrix rotY * rotateZMatrix rotZ
				local keyTimes = #()
				
				if cam.position.controller != undefined then
				(
					for i = 1 to cam.position.controller.keys.count do
						appendIfUnique keyTimes cam.position.controller.keys[i].time
				)
				if tgt.position.controller != undefined then
				(
					for i = 1 to tgt.position.controller.keys.count do
						appendIfUnique keyTimes tgt.position.controller.keys[i].time
				)
				
				sort keyTimes
				for t in keyTimes do
				(
					at time t
					(
						local camPos = cam.pos
						local tgtPos = tgt.position
						local newCamPos = camPos * rotMatrix
						local newTgtPos = tgtPos * rotMatrix
						with animate on
						(
							cam.pos = newCamPos
							tgt.position = newTgtPos
						)
					)
				)
			)
			
			fn rotateTargetCamAnimation cam rotX rotY rotZ cleanupKeys =
			(
				if cam == undefined then
				(
					messageBox "No camera selected!" title:"Error"
					return()
				)
				
				if cam.type != #target then
				(
					messageBox "Camera must be a Target Camera!" title:"Error"
					return()
				)
				pushPrompt "Getting animated frames... 5%"
				
				originalKeyFrames = getAnimatedFrames cam
				if originalKeyFrames.count == 0 then
				(
					messageBox "No animation found on camera!" title:"Warning"
					return()
				)
				startFrame = originalKeyFrames[1]
				endFrame = originalKeyFrames[originalKeyFrames.count]
				pushPrompt "Baking animation... 25%"
				
				-- Step 1: bake all frames
				bakeAnimation cam startFrame endFrame
				pushPrompt "Applying rotation... 50%"
				SetMatrix = rotateYPRMatrix rotX rotY rotZ
				disableSceneRedraw()
				
				-- step 2: apply rotation
				for f = startFrame to endFrame do
				(
					at time f
					(
						in coordsys world backPos = cam.position
						in coordsys world backTargetPos = cam.target.position
						
						with animate on
						(
							in coordsys SetMatrix cam.position = backPos
							in coordsys SetMatrix cam.target.position = backTargetPos
						)
					)
				)
				
				-- step 3: clean extra keys if enabled
				if cleanupKeys then
				(
					pushPrompt "Cleaning up keys... 75%"
					cleanupBakedKeys cam originalKeyFrames startFrame endFrame
				)
				popPrompt()
				displayTempPrompt "Rotation applied successfully!" 5000
			)
			
			-----------------------------------------------------------------------------------------
			-----------------------------------------------------------------------------------------
			
			fn applyFovOffset cam fovOffset =
			(
				sliderTime = 0
				pushPrompt "Getting FOV keyframes... 5%"
				local fovKeys = getKeysFromController cam.fov.controller
				if fovKeys.count == 0 then
				(
					messageBox "No FOV animation found on camera!" title:"Warning"
					return()
				)
				pushPrompt "Applying FOV offset... 50%"
				currentFrame = sliderTime
				disableSceneRedraw()
				
				for f in fovKeys do
				(
					at time f
					(
						with animate on
						(
							local currentFov = cam.fov
							cam.fov = currentFov + fovOffset
						)
					)
				)
				popPrompt()
				displayTempPrompt "FOV offset applied successfully!" 5000
				
				sliderTime = currentFrame
				enableSceneRedraw()
				completeRedraw()
			)
			
			------------------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------------------
			------------------------------------------------------------------------------------------------------------
			on btnPickCam pressed do
			(
				selectedCamera = selection[1]
				if selectedCamera != undefined and superClassOf selectedCamera == Camera then
				(
					if selectedCamera.parent != undefined then 
					(
						parentCamera = selectedCamera.parent
					)
					dn_lblCam.Text = selectedCamera.name
					btnExport.enabled = true
					btnApplyRot.enabled = true
					btnApplyFov.enabled = true
				)
				else
				(
					dn_lblCam.Text = ""
					btnExport.enabled = false
					btnApplyRot.enabled = false
					btnApplyFov.enabled = false
				)
			)			
			on btnDelCam pressed do ( cleanDialog() )
			
			on btnExport pressed do 
			(
				clearlistener()
				if selectedCamera == undefined then
				(
					format "Please select a camera!\n"
					return()
				)
				
				local savePath = getSaveFileName caption:"Save JSON File" \
								 types:"JSON Files (*.json)|*.json|All Files (*.*)|*.*"
				
				if savePath != undefined then
				(
					disableSceneRedraw() 
					setWaitCursor()
					exportCameraJSON selectedCamera savePath
				)
				setArrowCursor()
				enableSceneRedraw()
				CompleteRedraw()
				gc()
			)
			on btnImport pressed do 
			(
				clearlistener()
				local openPath = getOpenFileName caption:"Open JSON File" \
								 types:"JSON Files (*.json)|*.json|All Files (*.*)|*.*"
				
				if openPath != undefined then
				(
					disableSceneRedraw()
					setWaitCursor()
					importCameraJSON openPath
				)
				setArrowCursor()
				enableSceneRedraw()
				CompleteRedraw()
				gc()
			)
			
			on btnApplyRot pressed do
			(
				if selectedCamera != undefined and parentCamera != undefined then
				(
					rotX = spnRotX.value
					rotY = spnRotY.value
					rotZ = spnRotZ.value
					
					if rotX == 0 and rotY == 0 and rotZ == 0 then
					(
						messageBox "Please set at least one rotation value!" title:"Warning"
					)
					else
					(
						-- Synchronize keyframes and store camera data
						local syncData = syncKeyframes parentCamera selectedCamera
						local keyTimes = syncData[1]
						local camPositions = syncData[2]
						local camFOVs = syncData[3]						
						
						-- Create Target Camera
						local camName = (selectedCamera.name + "_DL")
						targetCam = buildCam camName typeCam:#target
						targetObj = targetCam.target
						
						-- Transfer animation
						for i = 1 to keyTimes.count do
						(
							local t = keyTimes[i]
							at time t
							(
								local worldTargetPos = parentCamera.transform.position
								local dummyRot = parentCamera.rotation
								local rollAngle = (quatToEuler dummyRot).y
								local worldCamPos = camPositions[i]
								local camFOV = camFOVs[i]
								with animate on
								(
									targetObj.pos = worldTargetPos
									targetCam.pos = worldCamPos
									targetCam.fov = camFOV
									targetCam.controller.roll_angle = rollAngle
								)
							)
						)
						selectedCamera.isHidden = true
						parentCamera.isHidden = true
						------
						select targetCam
						selectedCamera = selection[1]
						dn_lblCam.Text = selectedCamera.name
						parentCamera = undefined
						------
						undo "Rotate Target Camera Animation" on
						(
							rotateAnimation targetCam targetObj spnRotX.value spnRotY.value spnRotZ.value
						)
						sliderTime = 0
						enableSceneRedraw()
						completeRedraw()
						gc()
						---------------
						spnRotX.value = 0
						spnRotY.value = 0
						spnRotZ.value = 180
					)
				) else (
					rotX = spnRotX.value
					rotY = spnRotY.value
					rotZ = spnRotZ.value
					
					if rotX == 0 and rotY == 0 and rotZ == 0 then
					(
						messageBox "Please set at least one rotation value!" title:"Warning"
					)
					else
					(
						undo "Rotate Target Camera Animation" on
						(
							targetCam = selectedCamera
							targetObj = targetCam.target
							rotateAnimation targetCam targetObj spnRotX.value spnRotY.value spnRotZ.value
							--rotateTargetCamAnimation selectedCamera rotX rotY rotZ true
						)
						sliderTime = 0
						enableSceneRedraw()
						completeRedraw()
						gc()
						---------------
						spnRotX.value = 0
						spnRotY.value = 0
						spnRotZ.value = 180
					)					
					
				)
			)
			on btnApplyFov pressed do
			(
				if selectedCamera != undefined then
				(
					local fovOffset = spnFovOffset.value
					if fovOffset != 0 then
					(
						applyFovOffset selectedCamera fovOffset
						spnFovOffset.value = 0
					)
				)
			)
			on btnCFreeToTarget pressed do 
			(
				local cam = undefined
				local obj = selection[1]
				if obj != undefined do 
				(
					if ((classOf obj) == Freecamera) then 
					(
						cam = obj
						clearSelection()
						Select cam
						convertCamera cam targetDistance:7.5
					)
				)					
			)
			--------------------------------------------
			
			on UICameraDanceDialog open do 
			(
				dn_lblCam.TextAlign = (dotNetClass "System.Drawing.ContentAlignment").MiddleLeft
				dn_lblCam.Text = ""
				dn_lblCam.BackColor= (dotNetClass "System.Drawing.Color").fromArgb 40 40 40
				dn_lblCam.ForeColor= (dotNetClass "System.Drawing.Color").LightGray
				dn_lblCam.Padding = (dotNetObject "System.Windows.Forms.Padding" 5 0 0 0)
				-----------------------------------------------------------------------------------------------------------
				dotNet_labelSetup lblTemp1 "________________________________________" 70 align:#center
				lblTemp1.ForeColor= (dotNetClass "System.Drawing.Color").fromArgb 90 90 90
				dotNet_labelSetup lblTemp0 "________________________________________" 70 align:#center
				lblTemp0.ForeColor= (dotNetClass "System.Drawing.Color").fromArgb 90 90 90				
				dotNet_labelSetup lblTemp2 "________________________________________" 70 align:#center
				lblTemp2.ForeColor= (dotNetClass "System.Drawing.Color").fromArgb 90 90 90
				dotNet_labelSetup lblTemp3 "_______________" 70 align:#left
				lblTemp3.ForeColor= (dotNetClass "System.Drawing.Color").fromArgb 90 90 90				
				dotNet_labelSetup lblTemp4 "________________________________________" 70 align:#center
				lblTemp4.ForeColor= (dotNetClass "System.Drawing.Color").fromArgb 90 90 90						
				------
				dotNet_labelSetup lblTitle "Camera to GTA CLEO Redux \nAnimation -> JSON Converter" 70 align:#center
				lblTitle.ForeColor= (dotNetClass "System.Drawing.Color").LightGray
				------
				dotNet_labelSetup lblCam "Camera:" 70 align:#left
				dotNet_labelSetup lblImpExp "Import/Export JSON" 70 align:#left
				dotNet_labelSetup lblSett "Settings" 70 align:#left
				dotNet_labelSetup lblInfoSett "Create a Target Camera and Rotate it" 70 align:#center
				dotNet_labelSetup lblby "by J16D" 70 align:#center
			)
			on UICameraDanceDialog close do ( gc() )
		)
		createDialog UICameraDanceDialog width:gtaCameraDance.d_width height:gtaCameraDance.d_height style:#(#style_sysmenu, #style_toolwindow)
		uiInst=UICameraDanceDialog
	),
	
	fn run =
	(
		if gtaCameraDance.uiInst == undefined then 
		(
			gtaCameraDance.ui()
		)
		else
		(
			destroyDialog gtaCameraDance.uiInst
			gtaCameraDance.uiInst = undefined
		)
		clearListener()		
	)
)
gtaCameraDance = gtaCam_struct()
gtaCameraDance.run()
