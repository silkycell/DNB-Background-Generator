package;

import Shaders.GlitchEffect;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUITabMenu;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.system.frontEnds.SoundFrontEnd;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.system.Capabilities;

/*
	Based off of Lars Doucet's FileBrowse Demo
	https://github.com/HaxeFlixel/flixel-demos/tree/dev/UserInterface/FileBrowse
 */
class PlayState extends FlxUIState
{
	static inline var MIN_SCALE:Float = 0.1;
	static inline var MAX_SCALE:Float = 5;
	static inline var ZOOM_FACTOR:Int = 15;

	var camBG:FlxCamera;
	var camHUD:FlxCamera;

	var camFollow:FlxObject; // still never get why i have to do this
	var github:FlxSprite;

	var settings:FlxUITabMenu;

	var tooltipText:FlxText;
	var loadButton:FlxButton;
	var chosenImage:FlxSprite;
	var _displayWidth:Float;
	var _displayHeight:Float;
	var scaleNotif:FlxText;

	var backgroundShader:GlitchEffect;

	// Image Settings
	var scaleX:FlxUINumericStepper;
	var scaleY:FlxUINumericStepper;
	var antialiasing:FlxUICheckBox;
	// Control Settings
	var resetPos:FlxButton;
	var resetZoom:FlxButton;
	// Shader Settings
	var waveAmp:FlxUINumericStepper;
	var waveFreq:FlxUINumericStepper;
	var waveSpd:FlxUINumericStepper;
	var resetShaderSettings:FlxButton;

	override public function create():Void
	{
		FlxG.autoPause = false;
		FlxG.sound.soundTrayEnabled = false;

		camFollow = new FlxObject();
		camFollow.screenCenter();

		camBG = new FlxCamera();
		camBG.follow(camFollow);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.add(camBG, false);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.setDefaultDrawTarget(camHUD, true);

		backgroundShader = new GlitchEffect();
		backgroundShader.waveAmplitude = 0.1;
		backgroundShader.waveFrequency = 5;
		backgroundShader.waveSpeed = 2;
		backgroundShader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-1000, 1000);

		chosenImage = new FlxSprite(0, 0);
		chosenImage.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		chosenImage.antialiasing = true;
		chosenImage.shader = backgroundShader.shader;
		chosenImage.cameras = [camBG];
		add(chosenImage);

		var loadButton = new FlxButton(4, 4, "Open Image", _showFileDialog);
		add(loadButton);

		tooltipText = new FlxText(loadButton.width + 15, 4, Std.int(FlxG.width - (loadButton.width + 15) - 5), "Click the button to load a PNG or JPG!");
		tooltipText.setFormat("assets/fonts/comic.ttf", 16, FlxColor.WHITE, LEFT);
		add(tooltipText);

		scaleNotif = new FlxText(FlxG.width - 100, FlxG.height - 20, 100, 100);
		scaleNotif.setFormat("assets/fonts/comic.ttf", 16, FlxColor.WHITE, RIGHT);
		add(scaleNotif);

		var tabs = [
			{name: 'Shader Settings', label: 'Shader Settings'},
			{name: 'Image Settings', label: 'Image Settings'},
			{name: 'Control Settings', label: 'Control Settings'},
		];

		settings = new FlxUITabMenu(null, tabs, true);
		settings.resize(250, 120);
		settings.x = FlxG.width - 275;
		settings.y = 25;
		settings.selected_tab_id = 'Image Settings';
		add(settings);

		// Image

		var tab_image = new FlxUI(null, settings);
		tab_image.name = "Image Settings";

		scaleX = new FlxUINumericStepper(15, 30, 0.01, chosenImage.scale.x, 0, 999, 3);
		tab_image.add(scaleX);
		tab_image.add(new FlxText(15, scaleX.y - 18, 0, 'Scale:'));

		scaleY = new FlxUINumericStepper(scaleX.x + scaleX.width + 5, 30, 0.01, chosenImage.scale.y, 0, 999, 3);
		tab_image.add(scaleY);

		antialiasing = new FlxUICheckBox(scaleX.x, scaleX.y + 40, null, null, "Antialiasing", 80);
		antialiasing.checked = chosenImage.antialiasing;
		tab_image.add(antialiasing);

		settings.addGroup(tab_image);

		// Control

		var tab_control = new FlxUI(null, settings);
		tab_control.name = "Control Settings";

		resetPos = new FlxButton(15, 30, "Reset Position", function()
		{
			camFollow.screenCenter();
		});

		tab_control.add(resetPos);

		resetZoom = new FlxButton(resetPos.x + resetPos.width + 5, 30, "Reset Zoom", function()
		{
			camBG.zoom = 0;
		});

		tab_control.add(resetZoom);
		settings.addGroup(tab_control);

		// Shader

		var tab_shader = new FlxUI(null, settings);
		tab_shader.name = "Shader Settings";

		waveAmp = new FlxUINumericStepper(15, 30, 0.01, backgroundShader.waveAmplitude, -999, 999, 3);
		tab_shader.add(waveAmp);
		tab_shader.add(new FlxText(15, waveAmp.y - 18, 0, 'Amplitude'));

		waveFreq = new FlxUINumericStepper(waveAmp.x + waveAmp.width + 5, 30, 0.1, backgroundShader.waveFrequency, -999, 999, 3);
		tab_shader.add(waveFreq);
		tab_shader.add(new FlxText(waveFreq.x, waveFreq.y - 18, 0, 'Frequency'));

		waveSpd = new FlxUINumericStepper(15, waveAmp.y + waveAmp.height + 5, 0.05, backgroundShader.waveSpeed, -999, 999, 3);
		tab_shader.add(waveSpd);
		tab_shader.add(new FlxText(15, waveSpd.y + 18, 0, 'Speed'));

		resetShaderSettings = new FlxButton(waveSpd.x + waveSpd.width + 5, waveSpd.y, "Reset Shader", function()
		{
			backgroundShader.waveAmplitude = 0.1;
			backgroundShader.waveFrequency = 5;
			backgroundShader.waveSpeed = 2;

			waveAmp.value = backgroundShader.waveAmplitude;
			waveFreq.value = backgroundShader.waveFrequency;
			waveSpd.value = backgroundShader.waveSpeed;
			backgroundShader.shader.uTime.value[0] = new flixel.math.FlxRandom().float(-1000, 1000);
		});

		tab_shader.add(resetShaderSettings);

		settings.addGroup(tab_shader);

		// Tooltip

		var tipTextArray:Array<String> = "Scroll - Camera Zoom In/Out
		\nWASD/Arrow Keys - Move Camera
		\nSpace - Hide UI
		\nCTRL - Fullscreen
		\nHold Shift to Move 2x faster
		\n
		\nCheck \"Presets.txt\" for a list of Preset Shader Settings!\n".split('\n');

		for (i in 0...tipTextArray.length - 1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.setFormat("assets/fonts/comic.ttf", 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		github = new FlxSprite().loadGraphic("assets/images/github.png");
		github.setGraphicSize(Std.int(50));
		github.updateHitbox();
		github.antialiasing = true;
		github.y = FlxG.height - github.width - 5;
		github.x = 5;
		add(github);

		BitmapData.loadFromFile('assets/images/DefaultBG.png').onComplete(function(bitmapData)
		{
			showImage(bitmapData);
		});
	}

	override public function update(elapsed:Float):Void
	{
		backgroundShader.shader.uTime.value[0] += elapsed;

		if (FlxG.mouse.wheel != 0)
			camBG.zoom += FlxG.mouse.wheel / ZOOM_FACTOR;

		var moveAmount = 1;

		if (FlxG.keys.pressed.SHIFT)
			moveAmount *= 2;

		if (FlxG.keys.anyPressed([W, UP]))
			camFollow.y -= moveAmount;
		if (FlxG.keys.anyPressed([A, LEFT]))
			camFollow.x -= moveAmount;
		if (FlxG.keys.anyPressed([D, RIGHT]))
			camFollow.x += moveAmount;
		if (FlxG.keys.anyPressed([S, DOWN]))
			camFollow.y += moveAmount;

		if (FlxG.keys.justPressed.SPACE)
		{
			camHUD.visible = !camHUD.visible;
			FlxG.mouse.visible = !FlxG.mouse.visible;
		}

		if (FlxG.keys.justPressed.CONTROL)
			FlxG.fullscreen = !FlxG.fullscreen;

		// Little fading effect for the scale text
		if (scaleNotif.alpha > 0)
			scaleNotif.alpha -= 0.03;

		if (FlxG.mouse.overlaps(github))
		{
			github.alpha = 1;
			github.scale.x = (FlxMath.lerp(github.scale.x, 0.12, 0.1));
			github.scale.y = (FlxMath.lerp(github.scale.y, 0.12, 0.1));

			if (FlxG.mouse.justPressed)
				FlxG.openURL("https://github.com/FoxelTheFennic/DNB-Background-Generator");
		}
		else
		{
			github.alpha = 0.5;
			github.scale.x = (FlxMath.lerp(github.scale.x, 0.098, 0.1));
			github.scale.y = (FlxMath.lerp(github.scale.y, 0.098, 0.1));
		}

		super.update(elapsed);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == scaleX)
				updateScale(FlxPoint.get(scaleX.value, 0));
			else if (sender == scaleY)
				updateScale(FlxPoint.get(0, scaleY.value));
			else if (sender == waveAmp)
				backgroundShader.waveAmplitude = waveAmp.value;
			else if (sender == waveFreq)
				backgroundShader.waveFrequency = waveFreq.value;
			else if (sender == waveSpd)
				backgroundShader.waveSpeed = waveSpd.value;
		}
		else if (id == FlxUICheckBox.CLICK_EVENT && (sender is FlxUICheckBox))
		{
			switch (sender)
			{
				case antialiasing:
					chosenImage.antialiasing = antialiasing.checked;
			}
		}
	}

	function updateScale(newScale:FlxPoint):Void
	{
		if (newScale.x == 0)
			newScale.x = chosenImage.scale.x;

		if (newScale.y == 0)
			newScale.y = chosenImage.scale.y;

		chosenImage.scale.set(newScale.x, newScale.y);
		scaleNotif.text = "x" + FlxMath.roundDecimal(chosenImage.scale.x, 2);
		scaleNotif.alpha = 1;
		centerImage();
		newScale.put();
	}

	function centerImage():Void
	{
		chosenImage.offset.x = _displayWidth * chosenImage.scale.x / 2;
		chosenImage.offset.y = _displayHeight * chosenImage.scale.y / 2;
		chosenImage.centerOffsets();
	}

	function _showFileDialog():Void
	{
		var fr:FileReference = new FileReference();
		fr.addEventListener(Event.SELECT, _onSelect, false, 0, true);
		fr.addEventListener(Event.CANCEL, _onCancel, false, 0, true);
		var filters:Array<FileFilter> = new Array<FileFilter>();
		filters.push(new FileFilter("PNG Files", "*.png"));
		filters.push(new FileFilter("JPEG Files", "*.jpg;*.jpeg"));
		fr.browse();
	}

	function _onSelect(E:Event):Void
	{
		var fr:FileReference = cast(E.target, FileReference);
		tooltipText.text = fr.name;
		fr.addEventListener(Event.COMPLETE, _onLoad, false, 0, true);
		fr.load();
	}

	function _onLoad(E:Event):Void
	{
		var fr:FileReference = cast E.target;
		fr.removeEventListener(Event.COMPLETE, _onLoad);

		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _onImgLoad);
		loader.loadBytes(fr.data);
	}

	function _onImgLoad(E:Event):Void
	{
		var loaderInfo:LoaderInfo = cast E.target;
		loaderInfo.removeEventListener(Event.COMPLETE, _onImgLoad);
		var bmp:Bitmap = cast(loaderInfo.content, Bitmap);
		showImage(bmp.bitmapData);
	}

	function _onCancel(_):Void
	{
		tooltipText.text = "Cancelled!";
	}

	function showImage(Data:BitmapData):Void
	{
		chosenImage.scale.set(1, 1);

		var imgWidth:Float = FlxG.width / Data.width;
		var imgHeight:Float = FlxG.height / Data.height;

		var scale:Float = imgWidth <= imgHeight ? imgWidth : imgHeight;

		// Cap the scale at x1
		if (scale > 1)
			scale = 1;

		_displayWidth = Data.width * scale;
		_displayHeight = Data.height * scale;
		chosenImage.makeGraphic(Std.int(_displayWidth), Std.int(_displayHeight), FlxColor.BLACK);

		var data2:BitmapData = chosenImage.pixels.clone();
		var matrix:Matrix = new Matrix();
		matrix.identity();
		matrix.scale(scale, scale);
		data2.fillRect(data2.rect, FlxColor.BLACK);
		data2.draw(Data, matrix, null, null, null, true);
		chosenImage.pixels = data2;

		// Center the image
		chosenImage.x = (FlxG.width - _displayWidth) / 2;
		chosenImage.y = (FlxG.height - _displayHeight) / 2;
	}
}
