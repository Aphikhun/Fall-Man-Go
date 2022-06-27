
Enum.FontStyle = {
	DroidSans			= "DroidSans",					--DroidSans
	HarmonySansBlack	= "HarmonyOS_Sans_SC_Black",	--鸿蒙字体-黑体
	HarmonySansBold		= "HarmonyOS_Sans_SC_Bold",		--鸿蒙字体-粗体
	HarmonySansRegular	= "HarmonyOS_Sans_SC_Regular"	--鸿蒙字体-常规
}

Enum.FontWeight = {
	Light				= -1,	--细体
	Regular				= 0,	--常规
	Bold				= 1,	--粗体
}

Enum.WidgetType = {
	Frame						= "Engine/DefaultWindow",
	Text						= "WindowsLook/StaticText",
	Image						= "WindowsLook/StaticImage",
	Button						= "WindowsLook/Button",
	ProgressBar					= "WindowsLook/ProgressBar",
	Editbox						= "WindowsLook/Editbox",
	Checkbox					= "WindowsLook/Checkbox",
	RadioButton					= "WindowsLook/RadioButton",
	HorizontalSlider			= "WindowsLook/HorizontalSlider",
	VerticalSlider				= "WindowsLook/VerticalSlider",
	ScrollableView				= "WindowsLook/ScrollableView",
	ActorWindow					= "WindowsLook/ActorWindow",
	EffectWindow				= "WindowsLook/EffectWindow",
	HorizontalLayoutContainer	= "HorizontalLayoutContainer",
	VerticalLayoutContainer		= "VerticalLayoutContainer",
	GridView					= "GridView",
}

Enum.BlendMode = {
	No				= 0,
	Multiply		= 1,
	ColorDodge		= 2,
}

Enum.ScrollRestrictType = {
	Clamped			= 0,	--限制
	Elastic			= 1,	--弹性
	Unrestricted	= 2,	--不限制
}

Enum.AlignmentFormat = {
	TopLeft			= 0,
	TopCenter		= 1,
	TopRight		= 2,
	MiddleLeft		= 3,
	MiddleCenter	= 4,
	MiddleRight		= 5,
	BottomLeft		= 6,
	BottomCenter	= 7,
	BottomRight		= 8,
}

Enum.TextHorizontalFormat = {
	Left			= 0,
	Center			= 1,
	Right			= 2,
}

Enum.TextVerticalFormat = {
	Top				= 0,
	Center			= 1,
	Bottom			= 2,
}

Enum.AutoFrameSize = {
	Fixed					= 0,
	SelfAdaptiveHeight		= 1,
	SelfAdaptiveWidth		= 2,
	SelfAdaptive			= 3,
}