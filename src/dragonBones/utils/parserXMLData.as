package dragonBones.utils
{
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.ArmatureData;
	import dragonBones.utils.ConstValues;

	public function parserXMLData(xml:XML):SkeletonData
	{
		var frameRate:uint = int(xml.@[ConstValues.A_FRAME_RATE]);
		
		var data:SkeletonData = new SkeletonData();
		data.name = xml.@[ConstValues.A_NAME];
		
		for each(var armatureXML:XML in xml[ConstValues.ARMATURE])
		{
			data.addArmatureData(parseArmatureData(armatureXML, data, frameRate));
		}
		
		return data;
	}
}

import dragonBones.objects.AnimationData;
import dragonBones.objects.ArmatureData;
import dragonBones.objects.BoneData;
import dragonBones.objects.DBTransform;
import dragonBones.objects.DisplayData;
import dragonBones.objects.Frame;
import dragonBones.objects.SkeletonData;
import dragonBones.objects.SkinData;
import dragonBones.objects.SlotData;
import dragonBones.objects.Timeline;
import dragonBones.objects.TransformFrame;
import dragonBones.objects.TransformTimeline;
import dragonBones.utils.ConstValues;
import dragonBones.utils.DBDataUtil;

import flash.geom.ColorTransform;
import flash.geom.Point;

const ANGLE_TO_RADIAN:Number = Math.PI / 180;

function parseArmatureData(armatureXML:XML, data:SkeletonData, frameRate:uint):ArmatureData
{
	var armatureData:ArmatureData = new ArmatureData();
	armatureData.name = armatureXML.@[ConstValues.A_NAME];
	
	for each(var boneXML:XML in armatureXML[ConstValues.BONE])
	{
		armatureData.addBoneData(parseBoneData(boneXML));
	}
	
	for each(var skinXML:XML in armatureXML[ConstValues.SKIN])
	{
		armatureData.addSkinData(parseSkinData(skinXML, data));
	}
	
	DBDataUtil.transformArmatureData(armatureData);
	armatureData.sortBoneDataList();
	
	for each(var animationXML:XML in armatureXML[ConstValues.ANIMATION])
	{
		armatureData.addAnimationData(parseAnimationData(animationXML, armatureData, frameRate));
	}
	
	return armatureData;
}

function parseBoneData(boneXML:XML):BoneData
{
	var boneData:BoneData = new BoneData();
	boneData.name = boneXML.@[ConstValues.A_NAME];
	boneData.parent = boneXML.@[ConstValues.A_PARENT];
	
	parseTransform(boneXML[ConstValues.TRANSFORM][0], boneData.global, boneData.pivot);
	boneData.transform.copy(boneData.global);
	
	return boneData;
}

function parseSkinData(skinXML:XML, data:SkeletonData):SkinData
{
	var skinData:SkinData = new SkinData();
	skinData.name = skinXML.@[ConstValues.A_NAME];
	
	for each(var slotXML:XML in skinXML[ConstValues.SLOT])
	{
		skinData.addSlotData(parseSlotData(slotXML, data));
	}
	
	return skinData;
}

function parseSlotData(slotXML:XML, data:SkeletonData):SlotData
{
	var slotData:SlotData = new SlotData();
	slotData.name = slotXML.@[ConstValues.A_NAME];
	slotData.parent = slotXML.@[ConstValues.A_PARENT];
	slotData.zOrder = slotXML.@[ConstValues.A_Z_ORDER];
	for each(var displayXML:XML in slotXML[ConstValues.DISPLAY])
	{
		slotData.addDisplayData(parseDisplayData(displayXML, data));
	}
	
	return slotData;
}

function parseDisplayData(displayXML:XML, data:SkeletonData):DisplayData
{
	var displayData:DisplayData = new DisplayData();
	displayData.name = displayXML.@[ConstValues.A_NAME];
	displayData.type = displayXML.@[ConstValues.A_TYPE];
	
	displayData.pivot = data.addSubTexturePivot(
		0, 
		0, 
		displayData.name
	);
	
	parseTransform(displayXML[ConstValues.TRANSFORM][0], displayData.transform, displayData.pivot);

	return displayData;
}

function parseAnimationData(animationXML:XML, armatureData:ArmatureData, frameRate:uint):AnimationData
{
	var animationData:AnimationData = new AnimationData();
	animationData.name = animationXML.@[ConstValues.A_NAME];
	animationData.frameRate = frameRate;
	animationData.loop = int(animationXML.@[ConstValues.A_LOOP]);
	animationData.fadeInTime = Number(animationXML.@[ConstValues.A_FADE_IN_TIME]);
	animationData.duration = Number(animationXML.@[ConstValues.A_DURATION]) / frameRate;
	animationData.scale = Number(animationXML.@[ConstValues.A_SCALE]);
	animationData.tweenEasing = Number(animationXML.@[ConstValues.A_TWEEN_EASING]);
	
	parseTimeline(animationXML, animationData, parseMainFrame, frameRate);
	
	var timeline:TransformTimeline;
	var timelineName:String;
	for each(var timelineXML:XML in animationXML[ConstValues.TIMELINE])
	{
		timeline = parseTransformTimeline(timelineXML, animationData.duration, frameRate);
		timelineName = timelineXML.@[ConstValues.A_NAME];
		animationData.addTimeline(timeline, timelineName);
	}
	
	DBDataUtil.addHideTimeline(animationData, armatureData);
	DBDataUtil.transformAnimationData(animationData, armatureData);
	
	return animationData;
}

function parseTimeline(timelineXML:XML, timeline:Timeline, frameParser:Function, frameRate:uint):void
{
	var position:Number = 0;
	var frame:Frame;
	for each(var frameXML:XML in timelineXML[ConstValues.FRAME])
	{
		frame = frameParser(frameXML, frameRate);
		frame.position = position;
		timeline.addFrame(frame);
		position += frame.duration;
	}
	if(frame)
	{
		frame.duration = timeline.duration - frame.position;
	}
}

function parseTransformTimeline(timelineXML:XML, duration:Number, frameRate:uint):TransformTimeline
{
	var timeline:TransformTimeline = new TransformTimeline();
	timeline.duration = duration;
	
	parseTimeline(timelineXML, timeline, parseTransformFrame, frameRate);
	
	timeline.scale = Number(timelineXML.@[ConstValues.A_SCALE]);
	timeline.offset = Number(timelineXML.@[ConstValues.A_OFFSET]);
	
	return timeline;
}

function parseFrame(frameXML:XML, frame:Frame, frameRate:uint):void
{
	frame.duration = Number(frameXML.@[ConstValues.A_DURATION]) / frameRate;
	frame.action = frameXML.@[ConstValues.A_ACTION];
	frame.event = frameXML.@[ConstValues.A_EVENT];
	frame.sound = frameXML.@[ConstValues.A_SOUND];
}

function parseMainFrame(frameXML:XML, frameRate:uint):Frame
{
	var frame:Frame = new Frame();
	parseFrame(frameXML, frame, frameRate);
	return frame;
}

function parseTransformFrame(frameXML:XML, frameRate:uint):TransformFrame
{
	var frame:TransformFrame = new TransformFrame();
	parseFrame(frameXML, frame, frameRate);
	
	frame.visible = uint(frameXML.@[ConstValues.A_HIDE]) != 1;
	frame.tweenEasing = Number(frameXML.@[ConstValues.A_TWEEN_EASING]);
	frame.tweenRotate = Number(frameXML.@[ConstValues.A_TWEEN_ROTATE]);
	frame.displayIndex = Number(frameXML.@[ConstValues.A_DISPLAY_INDEX]);
	frame.zOrder = Number(frameXML.@[ConstValues.A_Z_ORDER]);
	
	parseTransform(frameXML[ConstValues.TRANSFORM][0], frame.global, frame.pivot);
	frame.transform.copy(frame.global);
	
	var colorTransformXML:XML = frameXML[ConstValues.COLOR_TRANSFORM][0];
	if(colorTransformXML)
	{
		frame.color = new ColorTransform();
		frame.color.alphaOffset = Number(colorTransformXML.@[ConstValues.A_ALPHA_OFFSET]);
		frame.color.redOffset = Number(colorTransformXML.@[ConstValues.A_RED_OFFSET]);
		frame.color.greenOffset = Number(colorTransformXML.@[ConstValues.A_GREEN_OFFSET]);
		frame.color.blueOffset = Number(colorTransformXML.@[ConstValues.A_BLUE_OFFSET]);
		
		frame.color.alphaMultiplier = Number(colorTransformXML.@[ConstValues.A_ALPHA_MULTIPLIER]) * 0.01;
		frame.color.redMultiplier = Number(colorTransformXML.@[ConstValues.A_RED_MULTIPLIER]) * 0.01;
		frame.color.greenMultiplier = Number(colorTransformXML.@[ConstValues.A_GREEN_MULTIPLIER]) * 0.01;
		frame.color.blueMultiplier = Number(colorTransformXML.@[ConstValues.A_BLUE_MULTIPLIER]) * 0.01;
	}
	
	return frame;
}

function parseTransform(transformXML:XML, transform:DBTransform, pivot:Point):void
{
	if(transformXML)
	{
		if(transform)
		{
			transform.x = Number(transformXML.@[ConstValues.A_X]);
			transform.y = Number(transformXML.@[ConstValues.A_Y]);
			transform.skewX = Number(transformXML.@[ConstValues.A_SKEW_X]) * ANGLE_TO_RADIAN;
			transform.skewY = Number(transformXML.@[ConstValues.A_SKEW_Y]) * ANGLE_TO_RADIAN;
			transform.scaleX = Number(transformXML.@[ConstValues.A_SCALE_X]);
			transform.scaleY = Number(transformXML.@[ConstValues.A_SCALE_Y]);
		}
		if(pivot)
		{
			pivot.x = Number(transformXML.@[ConstValues.A_PIVOT_X]);
			pivot.y = Number(transformXML.@[ConstValues.A_PIVOT_Y]);
		}
	}
}