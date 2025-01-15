package imgui

when ODIN_OS == .Linux || ODIN_OS == .Darwin {
	@(require) foreign import stdcpp "system:c++"
}

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		foreign import lib "imgui_windows_x64.lib"
	} else {
		foreign import lib "imgui_windows_arm64.lib"
	}
} else when ODIN_OS == .Linux {
	when ODIN_ARCH == .amd64 {
		foreign import lib "imgui_linux_x64.a"
	} else {
		foreign import lib "imgui_linux_arm64.a"
	}
} else when ODIN_OS == .Darwin {
	when ODIN_ARCH == .amd64 {
		foreign import lib "imgui_darwin_x64.a"
	} else {
		foreign import lib "imgui_darwin_arm64.a"
	}
}

VERSION :: "1.91.6"
VERSION_NUM :: 19160
PAYLOAD_TYPE_COLOR_3F :: "_COL3F"
PAYLOAD_TYPE_COLOR_4F :: "_COL4F"
UNICODE_CODEPOINT_INVALID :: 0xFFFD
UNICODE_CODEPOINT_MAX :: 0xFFFF
COL32_R_SHIFT :: 0
COL32_G_SHIFT :: 8
COL32_B_SHIFT :: 16
COL32_A_SHIFT :: 24
COL32_A_MASK :: 0xFF000000
DRAWLIST_TEX_LINES_WIDTH_MAX :: 63

// Flags for ImGui::Begin()
// (Those are per-window flags. There are shared flags in ImGuiIO: io.ConfigWindowsResizeFromEdges and io.ConfigWindowsMoveFromTitleBarOnly)
WindowFlags :: bit_set[WindowFlag;i32]
WindowFlag :: enum i32 {
	NoTitleBar                = 0, // Disable title-bar
	NoResize                  = 1, // Disable user resizing with the lower-right grip
	NoMove                    = 2, // Disable user moving the window
	NoScrollbar               = 3, // Disable scrollbars (window can still scroll with mouse or programmatically)
	NoScrollWithMouse         = 4, // Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
	NoCollapse                = 5, // Disable user collapsing window by double-clicking on it. Also referred to as Window Menu Button (e.g. within a docking node).
	AlwaysAutoResize          = 6, // Resize every window to its content every frame
	NoBackground              = 7, // Disable drawing background color (WindowBg, etc.) and outside border. Similar as using SetNextWindowBgAlpha(0.0f).
	NoSavedSettings           = 8, // Never load/save settings in .ini file
	NoMouseInputs             = 9, // Disable catching mouse, hovering test with pass through.
	MenuBar                   = 10, // Has a menu-bar
	HorizontalScrollbar       = 11, // Allow horizontal scrollbar to appear (off by default). You may use SetNextWindowContentSize(ImVec2(width,0.0f)); prior to calling Begin() to specify width. Read code in imgui_demo in the "Horizontal Scrolling" section.
	NoFocusOnAppearing        = 12, // Disable taking focus when transitioning from hidden to visible state
	NoBringToFrontOnFocus     = 13, // Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus)
	AlwaysVerticalScrollbar   = 14, // Always show vertical scrollbar (even if ContentSize.y < Size.y)
	AlwaysHorizontalScrollbar = 15, // Always show horizontal scrollbar (even if ContentSize.x < Size.x)
	NoNavInputs               = 16, // No keyboard/gamepad navigation within the window
	NoNavFocus                = 17, // No focusing toward this window with keyboard/gamepad navigation (e.g. skipped by CTRL+TAB)
	UnsavedDocument           = 18, // Display a dot next to the title. When used in a tab/docking context, tab is selected when clicking the X + closure is not assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
}

WINDOW_FLAGS_NO_NAV :: WindowFlags{.NoNavInputs, .NoNavFocus}
WINDOW_FLAGS_NO_DECORATION :: WindowFlags{.NoTitleBar, .NoResize, .NoScrollbar, .NoCollapse}
WINDOW_FLAGS_NO_INPUTS :: WindowFlags{.NoMouseInputs, .NoNavInputs, .NoNavFocus}

// Flags for ImGui::BeginChild()
// (Legacy: bit 0 must always correspond to ImGuiChildFlags_Borders to be backward compatible with old API using 'bool border = false'.
// About using AutoResizeX/AutoResizeY flags:
// - May be combined with SetNextWindowSizeConstraints() to set a min/max size for each axis (see "Demo->Child->Auto-resize with Constraints").
// - Size measurement for a given axis is only performed when the child window is within visible boundaries, or is just appearing.
//   - This allows BeginChild() to return false when not within boundaries (e.g. when scrolling), which is more optimal. BUT it won't update its auto-size while clipped.
//     While not perfect, it is a better default behavior as the always-on performance gain is more valuable than the occasional "resizing after becoming visible again" glitch.
//   - You may also use ImGuiChildFlags_AlwaysAutoResize to force an update even when child window is not in view.
//     HOWEVER PLEASE UNDERSTAND THAT DOING SO WILL PREVENT BeginChild() FROM EVER RETURNING FALSE, disabling benefits of coarse clipping.
ChildFlags :: bit_set[ChildFlag;i32]
ChildFlag :: enum i32 {
	Borders                = 0, // Show an outer border and enable WindowPadding. (IMPORTANT: this is always == 1 == true for legacy reason)
	AlwaysUseWindowPadding = 1, // Pad with style.WindowPadding even if no border are drawn (no padding by default for non-bordered child windows because it makes more sense)
	ResizeX                = 2, // Allow resize from right border (layout direction). Enable .ini saving (unless ImGuiWindowFlags_NoSavedSettings passed to window flags)
	ResizeY                = 3, // Allow resize from bottom border (layout direction). "
	AutoResizeX            = 4, // Enable auto-resizing width. Read "IMPORTANT: Size measurement" details above.
	AutoResizeY            = 5, // Enable auto-resizing height. Read "IMPORTANT: Size measurement" details above.
	AlwaysAutoResize       = 6, // Combined with AutoResizeX/AutoResizeY. Always measure size even when child is hidden, always return true, always disable clipping optimization! NOT RECOMMENDED.
	FrameStyle             = 7, // Style the child window like a framed item: use FrameBg, FrameRounding, FrameBorderSize, FramePadding instead of ChildBg, ChildRounding, ChildBorderSize, WindowPadding.
	NavFlattened           = 8, // [BETA] Share focus scope, allow keyboard/gamepad navigation to cross over parent border to this child or between sibling child windows.
}

// Flags for ImGui::PushItemFlag()
// (Those are shared by all items)
ItemFlags :: bit_set[ItemFlag;i32]
ItemFlag :: enum i32 {
	NoTabStop         = 0, // false    // Disable keyboard tabbing. This is a "lighter" version of ImGuiItemFlags_NoNav.
	NoNav             = 1, // false    // Disable any form of focusing (keyboard/gamepad directional navigation and SetKeyboardFocusHere() calls).
	NoNavDefaultFocus = 2, // false    // Disable item being a candidate for default focus (e.g. used by title bar items).
	ButtonRepeat      = 3, // false    // Any button-like behavior will have repeat mode enabled (based on io.KeyRepeatDelay and io.KeyRepeatRate values). Note that you can also call IsItemActive() after any button to tell if it is being held.
	AutoClosePopups   = 4, // true     // MenuItem()/Selectable() automatically close their parent popup window.
	AllowDuplicateId  = 5, // false    // Allow submitting an item with the same identifier as an item already submitted this frame without triggering a warning tooltip if io.ConfigDebugHighlightIdConflicts is set.
}

// Flags for ImGui::InputText()
// (Those are per-item flags. There are shared flags in ImGuiIO: io.ConfigInputTextCursorBlink and io.ConfigInputTextEnterKeepActive)
InputTextFlags :: bit_set[InputTextFlag;i32]
InputTextFlag :: enum i32 {
	CharsDecimal        = 0, // Allow 0123456789.+-*/
	CharsHexadecimal    = 1, // Allow 0123456789ABCDEFabcdef
	CharsScientific     = 2, // Allow 0123456789.+-*/eE (Scientific notation input)
	CharsUppercase      = 3, // Turn a..z into A..Z
	CharsNoBlank        = 4, // Filter out spaces, tabs
	AllowTabInput       = 5, // Pressing TAB input a '\t' character into the text field
	EnterReturnsTrue    = 6, // Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider using IsItemDeactivatedAfterEdit() instead!
	EscapeClearsAll     = 7, // Escape key clears content if not empty, and deactivate otherwise (contrast to default behavior of Escape to revert)
	CtrlEnterForNewLine = 8, // In multi-line mode, validate with Enter, add new line with Ctrl+Enter (default is opposite: validate with Ctrl+Enter, add line with Enter).
	ReadOnly            = 9, // Read-only mode
	Password            = 10, // Password mode, display all characters as '*', disable copy
	AlwaysOverwrite     = 11, // Overwrite mode
	AutoSelectAll       = 12, // Select entire text when first taking mouse focus
	ParseEmptyRefVal    = 13, // InputFloat(), InputInt(), InputScalar() etc. only: parse empty string as zero value.
	DisplayEmptyRefVal  = 14, // InputFloat(), InputInt(), InputScalar() etc. only: when value is zero, do not display it. Generally used with ImGuiInputTextFlags_ParseEmptyRefVal.
	NoHorizontalScroll  = 15, // Disable following the cursor horizontally
	NoUndoRedo          = 16, // Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
	ElideLeft           = 17, // When text doesn't fit, elide left side to ensure right side stays visible. Useful for path/filenames. Single-line only!
	CallbackCompletion  = 18, // Callback on pressing TAB (for completion handling)
	CallbackHistory     = 19, // Callback on pressing Up/Down arrows (for history handling)
	CallbackAlways      = 20, // Callback on each iteration. User code may query cursor position, modify text buffer.
	CallbackCharFilter  = 21, // Callback on character inputs to replace or discard them. Modify 'EventChar' to replace or discard, or return 1 in callback to discard.
	CallbackResize      = 22, // Callback on buffer capacity changes request (beyond 'buf_size' parameter value), allowing the string to grow. Notify when the string wants to be resized (for string types which hold a cache of their Size). You will be provided a new BufSize in the callback and NEED to honor it. (see misc/cpp/imgui_stdlib.h for an example of using this)
	CallbackEdit        = 23, // Callback on any edit (note that InputText() already returns true on edit, the callback is useful mainly to manipulate the underlying buffer while focus is active)
}

// Flags for ImGui::TreeNodeEx(), ImGui::CollapsingHeader*()
TreeNodeFlags :: bit_set[TreeNodeFlag;i32]
TreeNodeFlag :: enum i32 {
	Selected             = 0, // Draw as selected
	Framed               = 1, // Draw frame with background (e.g. for CollapsingHeader)
	AllowOverlap         = 2, // Hit testing to allow subsequent widgets to overlap this one
	NoTreePushOnOpen     = 3, // Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
	NoAutoOpenOnLog      = 4, // Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
	DefaultOpen          = 5, // Default node to be open
	OpenOnDoubleClick    = 6, // Open on double-click instead of simple click (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
	OpenOnArrow          = 7, // Open when clicking on the arrow part (default for multi-select unless any _OpenOnXXX behavior is set explicitly). Both behaviors may be combined.
	Leaf                 = 8, // No collapsing, no arrow (use as a convenience for leaf nodes).
	Bullet               = 9, // Display a bullet instead of arrow. IMPORTANT: node can still be marked open/close if you don't set the _Leaf flag!
	FramePadding         = 10, // Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding() before the node.
	SpanAvailWidth       = 11, // Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line without using AllowOverlap mode.
	SpanFullWidth        = 12, // Extend hit box to the left-most and right-most edges (cover the indent area).
	SpanTextWidth        = 13, // Narrow hit box + narrow hovering highlight, will only cover the label text.
	SpanAllColumns       = 14, // Frame will span all columns of its container table (text will still fit in current column)
	NavLeftJumpsBackHere = 15, // (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
}

TREE_NODE_FLAGS_COLLAPSING_HEADER :: TreeNodeFlags{.Framed, .NoTreePushOnOpen, .NoAutoOpenOnLog}

// Flags for OpenPopup*(), BeginPopupContext*(), IsPopupOpen() functions.
// - To be backward compatible with older API which took an 'int mouse_button = 1' argument instead of 'ImGuiPopupFlags flags',
//   we need to treat small flags values as a mouse button index, so we encode the mouse button in the first few bits of the flags.
//   It is therefore guaranteed to be legal to pass a mouse button index in ImGuiPopupFlags.
// - For the same reason, we exceptionally default the ImGuiPopupFlags argument of BeginPopupContextXXX functions to 1 instead of 0.
//   IMPORTANT: because the default parameter is 1 (==ImGuiPopupFlags_MouseButtonRight), if you rely on the default parameter
//   and want to use another flag, you need to pass in the ImGuiPopupFlags_MouseButtonRight flag explicitly.
// - Multiple buttons currently cannot be combined/or-ed in those functions (we could allow it later).
PopupFlags :: bit_set[PopupFlag;i32]
PopupFlag :: enum i32 {
	MouseButtonLeft         = 0, // For BeginPopupContext*(): open on Left Mouse release. Guaranteed to always be == 0 (same as ImGuiMouseButton_Left)
	MouseButtonRight        = 1, // For BeginPopupContext*(): open on Right Mouse release. Guaranteed to always be == 1 (same as ImGuiMouseButton_Right)
	MouseButtonMiddle       = 2, // For BeginPopupContext*(): open on Middle Mouse release. Guaranteed to always be == 2 (same as ImGuiMouseButton_Middle)
	NoReopen                = 5, // For OpenPopup*(), BeginPopupContext*(): don't reopen same popup if already open (won't reposition, won't reinitialize navigation)
	NoOpenOverExistingPopup = 7, // For OpenPopup*(), BeginPopupContext*(): don't open if there's already a popup at the same level of the popup stack
	NoOpenOverItems         = 8, // For BeginPopupContextWindow(): don't return true when hovering items, only when hovering empty space
	AnyPopupId              = 10, // For IsPopupOpen(): ignore the ImGuiID parameter and test for any popup.
	AnyPopupLevel           = 11, // For IsPopupOpen(): search/test at any level of the popup stack (default test in the current level)
}

POPUP_FLAGS_ANY_POPUP :: PopupFlags{.AnyPopupId, .AnyPopupLevel}

// Flags for ImGui::Selectable()
SelectableFlags :: bit_set[SelectableFlag;i32]
SelectableFlag :: enum i32 {
	NoAutoClosePopups = 0, // Clicking this doesn't close parent popup window (overrides ImGuiItemFlags_AutoClosePopups)
	SpanAllColumns    = 1, // Frame will span all columns of its container table (text will still fit in current column)
	AllowDoubleClick  = 2, // Generate press events on double clicks too
	Disabled          = 3, // Cannot be selected, display grayed out text
	AllowOverlap      = 4, // (WIP) Hit testing to allow subsequent widgets to overlap this one
	Highlight         = 5, // Make the item be displayed as if it is hovered
}

// Flags for ImGui::BeginCombo()
ComboFlags :: bit_set[ComboFlag;i32]
ComboFlag :: enum i32 {
	PopupAlignLeft  = 0, // Align the popup toward the left by default
	HeightSmall     = 1, // Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
	HeightRegular   = 2, // Max ~8 items visible (default)
	HeightLarge     = 3, // Max ~20 items visible
	HeightLargest   = 4, // As many fitting items as possible
	NoArrowButton   = 5, // Display on the preview box without the square arrow button
	NoPreview       = 6, // Display only a square arrow button
	WidthFitPreview = 7, // Width dynamically calculated from preview contents
}

// Flags for ImGui::BeginTabBar()
TabBarFlags :: bit_set[TabBarFlag;i32]
TabBarFlag :: enum i32 {
	Reorderable                  = 0, // Allow manually dragging tabs to re-order them + New tabs are appended at the end of list
	AutoSelectNewTabs            = 1, // Automatically select new tabs when they appear
	TabListPopupButton           = 2, // Disable buttons to open the tab list popup
	NoCloseWithMiddleMouseButton = 3, // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
	NoTabListScrollingButtons    = 4, // Disable scrolling buttons (apply when fitting policy is ImGuiTabBarFlags_FittingPolicyScroll)
	NoTooltip                    = 5, // Disable tooltips when hovering a tab
	DrawSelectedOverline         = 6, // Draw selected overline markers over selected tab
	FittingPolicyResizeDown      = 7, // Resize tabs when they don't fit
	FittingPolicyScroll          = 8, // Add scroll buttons when tabs don't fit
}

// Flags for ImGui::BeginTabItem()
TabItemFlags :: bit_set[TabItemFlag;i32]
TabItemFlag :: enum i32 {
	UnsavedDocument              = 0, // Display a dot next to the title + set ImGuiTabItemFlags_NoAssumedClosure.
	SetSelected                  = 1, // Trigger flag to programmatically make the tab selected when calling BeginTabItem()
	NoCloseWithMiddleMouseButton = 2, // Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You may handle this behavior manually on user's side with if (IsItemHovered() && IsMouseClicked(2)) *p_open = false.
	NoPushId                     = 3, // Don't call PushID()/PopID() on BeginTabItem()/EndTabItem()
	NoTooltip                    = 4, // Disable tooltip for the given tab
	NoReorder                    = 5, // Disable reordering this tab or having another tab cross over this tab
	Leading                      = 6, // Enforce the tab position to the left of the tab bar (after the tab list popup button)
	Trailing                     = 7, // Enforce the tab position to the right of the tab bar (before the scrolling buttons)
	NoAssumedClosure             = 8, // Tab is selected when trying to close + closure is not immediately assumed (will wait for user to stop submitting the tab). Otherwise closure is assumed when pressing the X, so if you keep submitting the tab may reappear at end of tab bar.
}

// Flags for ImGui::IsWindowFocused()
FocusedFlags :: bit_set[FocusedFlag;i32]
FocusedFlag :: enum i32 {
	ChildWindows     = 0, // Return true if any children of the window is focused
	RootWindow       = 1, // Test from root window (top most parent of the current hierarchy)
	AnyWindow        = 2, // Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!
	NoPopupHierarchy = 3, // Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
}

FOCUSED_FLAGS_ROOT_AND_CHILD_WINDOWS :: FocusedFlags{.RootWindow, .ChildWindows}

// Flags for ImGui::IsItemHovered(), ImGui::IsWindowHovered()
// Note: if you are trying to check whether your mouse should be dispatched to Dear ImGui or to your app, you should use 'io.WantCaptureMouse' instead! Please read the FAQ!
// Note: windows with the ImGuiWindowFlags_NoInputs flag are ignored by IsWindowHovered() calls.
HoveredFlags :: bit_set[HoveredFlag;i32]
HoveredFlag :: enum i32 {
	ChildWindows                 = 0, // IsWindowHovered() only: Return true if any children of the window is hovered
	RootWindow                   = 1, // IsWindowHovered() only: Test from root window (top most parent of the current hierarchy)
	AnyWindow                    = 2, // IsWindowHovered() only: Return true if any window is hovered
	NoPopupHierarchy             = 3, // IsWindowHovered() only: Do not consider popup hierarchy (do not treat popup emitter as parent of popup) (when used with _ChildWindows or _RootWindow)
	AllowWhenBlockedByPopup      = 5, // Return true even if a popup window is normally blocking access to this item/window
	AllowWhenBlockedByActiveItem = 7, // Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
	AllowWhenOverlappedByItem    = 8, // IsItemHovered() only: Return true even if the item uses AllowOverlap mode and is overlapped by another hoverable item.
	AllowWhenOverlappedByWindow  = 9, // IsItemHovered() only: Return true even if the position is obstructed or overlapped by another window.
	AllowWhenDisabled            = 10, // IsItemHovered() only: Return true even if the item is disabled
	NoNavOverride                = 11, // IsItemHovered() only: Disable using keyboard/gamepad navigation state when active, always query mouse
	ForTooltip                   = 12, // Shortcut for standard flags when using IsItemHovered() + SetTooltip() sequence.
	Stationary                   = 13, // Require mouse to be stationary for style.HoverStationaryDelay (~0.15 sec) _at least one time_. After this, can move on same item/window. Using the stationary test tends to reduces the need for a long delay.
	DelayNone                    = 14, // IsItemHovered() only: Return true immediately (default). As this is the default you generally ignore this.
	DelayShort                   = 15, // IsItemHovered() only: Return true after style.HoverDelayShort elapsed (~0.15 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
	DelayNormal                  = 16, // IsItemHovered() only: Return true after style.HoverDelayNormal elapsed (~0.40 sec) (shared between items) + requires mouse to be stationary for style.HoverStationaryDelay (once per item).
	NoSharedDelay                = 17, // IsItemHovered() only: Disable shared delay system where moving from one item to the next keeps the previous timer for a short time (standard for tooltips with long delays)
}

HOVERED_FLAGS_ALLOW_WHEN_OVERLAPPED :: HoveredFlags {
	.AllowWhenOverlappedByItem,
	.AllowWhenOverlappedByWindow,
}
HOVERED_FLAGS_RECT_ONLY :: HoveredFlags {
	.AllowWhenBlockedByPopup,
	.AllowWhenBlockedByActiveItem,
	.AllowWhenOverlappedByItem,
	.AllowWhenOverlappedByWindow,
}
HOVERED_FLAGS_ROOT_AND_CHILD_WINDOWS :: HoveredFlags{.RootWindow, .ChildWindows}

// Flags for ImGui::BeginDragDropSource(), ImGui::AcceptDragDropPayload()
DragDropFlags :: bit_set[DragDropFlag;i32]
DragDropFlag :: enum i32 {
	SourceNoPreviewTooltip   = 0, // Disable preview tooltip. By default, a successful call to BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disables this behavior.
	SourceNoDisableHover     = 1, // By default, when dragging we clear data so that IsItemHovered() will return false, to avoid subsequent user code submitting tooltips. This flag disables this behavior so you can still call IsItemHovered() on the source item.
	SourceNoHoldToOpenOthers = 2, // Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
	SourceAllowNullID        = 3, // Allow items such as Text(), Image() that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
	SourceExtern             = 4, // External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
	PayloadAutoExpire        = 5, // Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged)
	PayloadNoCrossContext    = 6, // Hint to specify that the payload may not be copied outside current dear imgui context.
	PayloadNoCrossProcess    = 7, // Hint to specify that the payload may not be copied outside current process.
	AcceptBeforeDelivery     = 10, // AcceptDragDropPayload() will returns true even before the mouse button is released. You can then call IsDelivery() to test if the payload needs to be delivered.
	AcceptNoDrawDefaultRect  = 11, // Do not draw the default highlight rectangle when hovering over target.
	AcceptNoPreviewTooltip   = 12, // Request hiding the BeginDragDropSource tooltip from the BeginDragDropTarget site.
}

DRAG_DROP_FLAGS_ACCEPT_PEEK_ONLY :: DragDropFlags{.AcceptBeforeDelivery, .AcceptNoDrawDefaultRect}

// A primary data type
DataType :: enum i32 {
	S8     = 0, // signed char / char (with sensible compilers)
	U8     = 1, // unsigned char
	S16    = 2, // short
	U16    = 3, // unsigned short
	S32    = 4, // int
	U32    = 5, // unsigned int
	S64    = 6, // long long / __int64
	U64    = 7, // unsigned long long / unsigned __int64
	Float  = 8, // float
	Double = 9, // double
	Bool   = 10, // bool (provided for user convenience, not supported by scalar widgets)
}

DATA_TYPE_COUNT :: 11

// A cardinal direction
Dir :: enum i32 {
	None  = -1,
	Left  = 0,
	Right = 1,
	Up    = 2,
	Down  = 3,
}

DIR_COUNT :: 4

// A sorting direction
SortDirection :: enum i32 {
	None       = 0,
	Ascending  = 1, // Ascending = 0->9, A->Z etc.
	Descending = 2, // Descending = 9->0, Z->A etc.
}

// A key identifier (ImGuiKey_XXX or ImGuiMod_XXX value): can represent Keyboard, Mouse and Gamepad values.
// All our named keys are >= 512. Keys value 0 to 511 are left unused and were legacy native/opaque key values (< 1.87).
// Support for legacy keys was completely removed in 1.91.5.
// Read details about the 1.87+ transition : https://github.com/ocornut/imgui/issues/4921
// Note that "Keys" related to physical keys and are not the same concept as input "Characters", the later are submitted via io.AddInputCharacter().
// The keyboard key enum values are named after the keys on a standard US keyboard, and on other keyboard types the keys reported may not match the keycaps.
Key :: enum i32 {
	None                = 0,
	Tab                 = 512, // == ImGuiKey_NamedKey_BEGIN
	LeftArrow           = 513,
	RightArrow          = 514,
	UpArrow             = 515,
	DownArrow           = 516,
	PageUp              = 517,
	PageDown            = 518,
	Home                = 519,
	End                 = 520,
	Insert              = 521,
	Delete              = 522,
	Backspace           = 523,
	Space               = 524,
	Enter               = 525,
	Escape              = 526,
	LeftCtrl            = 527,
	LeftShift           = 528,
	LeftAlt             = 529,
	LeftSuper           = 530,
	RightCtrl           = 531,
	RightShift          = 532,
	RightAlt            = 533,
	RightSuper          = 534,
	Menu                = 535,
	_0                  = 536,
	_1                  = 537,
	_2                  = 538,
	_3                  = 539,
	_4                  = 540,
	_5                  = 541,
	_6                  = 542,
	_7                  = 543,
	_8                  = 544,
	_9                  = 545,
	A                   = 546,
	B                   = 547,
	C                   = 548,
	D                   = 549,
	E                   = 550,
	F                   = 551,
	G                   = 552,
	H                   = 553,
	I                   = 554,
	J                   = 555,
	K                   = 556,
	L                   = 557,
	M                   = 558,
	N                   = 559,
	O                   = 560,
	P                   = 561,
	Q                   = 562,
	R                   = 563,
	S                   = 564,
	T                   = 565,
	U                   = 566,
	V                   = 567,
	W                   = 568,
	X                   = 569,
	Y                   = 570,
	Z                   = 571,
	F1                  = 572,
	F2                  = 573,
	F3                  = 574,
	F4                  = 575,
	F5                  = 576,
	F6                  = 577,
	F7                  = 578,
	F8                  = 579,
	F9                  = 580,
	F10                 = 581,
	F11                 = 582,
	F12                 = 583,
	F13                 = 584,
	F14                 = 585,
	F15                 = 586,
	F16                 = 587,
	F17                 = 588,
	F18                 = 589,
	F19                 = 590,
	F20                 = 591,
	F21                 = 592,
	F22                 = 593,
	F23                 = 594,
	F24                 = 595,
	Apostrophe          = 596, // '
	Comma               = 597, // ,
	Minus               = 598, // -
	Period              = 599, // .
	Slash               = 600, // /
	Semicolon           = 601, // ;
	Equal               = 602, // =
	LeftBracket         = 603, // [
	Backslash           = 604, // \ (this text inhibit multiline comment caused by backslash)
	RightBracket        = 605, // ]
	GraveAccent         = 606, // `
	CapsLock            = 607,
	ScrollLock          = 608,
	NumLock             = 609,
	PrintScreen         = 610,
	Pause               = 611,
	Keypad0             = 612,
	Keypad1             = 613,
	Keypad2             = 614,
	Keypad3             = 615,
	Keypad4             = 616,
	Keypad5             = 617,
	Keypad6             = 618,
	Keypad7             = 619,
	Keypad8             = 620,
	Keypad9             = 621,
	KeypadDecimal       = 622,
	KeypadDivide        = 623,
	KeypadMultiply      = 624,
	KeypadSubtract      = 625,
	KeypadAdd           = 626,
	KeypadEnter         = 627,
	KeypadEqual         = 628,
	AppBack             = 629, // Available on some keyboard/mouses. Often referred as "Browser Back"
	AppForward          = 630,
	GamepadStart        = 631, // Menu (Xbox)      + (Switch)   Start/Options (PS)
	GamepadBack         = 632, // View (Xbox)      - (Switch)   Share (PS)
	GamepadFaceLeft     = 633, // X (Xbox)         Y (Switch)   Square (PS)        // Tap: Toggle Menu. Hold: Windowing mode (Focus/Move/Resize windows)
	GamepadFaceRight    = 634, // B (Xbox)         A (Switch)   Circle (PS)        // Cancel / Close / Exit
	GamepadFaceUp       = 635, // Y (Xbox)         X (Switch)   Triangle (PS)      // Text Input / On-screen Keyboard
	GamepadFaceDown     = 636, // A (Xbox)         B (Switch)   Cross (PS)         // Activate / Open / Toggle / Tweak
	GamepadDpadLeft     = 637, // D-pad Left                                       // Move / Tweak / Resize Window (in Windowing mode)
	GamepadDpadRight    = 638, // D-pad Right                                      // Move / Tweak / Resize Window (in Windowing mode)
	GamepadDpadUp       = 639, // D-pad Up                                         // Move / Tweak / Resize Window (in Windowing mode)
	GamepadDpadDown     = 640, // D-pad Down                                       // Move / Tweak / Resize Window (in Windowing mode)
	GamepadL1           = 641, // L Bumper (Xbox)  L (Switch)   L1 (PS)            // Tweak Slower / Focus Previous (in Windowing mode)
	GamepadR1           = 642, // R Bumper (Xbox)  R (Switch)   R1 (PS)            // Tweak Faster / Focus Next (in Windowing mode)
	GamepadL2           = 643, // L Trig. (Xbox)   ZL (Switch)  L2 (PS) [Analog]
	GamepadR2           = 644, // R Trig. (Xbox)   ZR (Switch)  R2 (PS) [Analog]
	GamepadL3           = 645, // L Stick (Xbox)   L3 (Switch)  L3 (PS)
	GamepadR3           = 646, // R Stick (Xbox)   R3 (Switch)  R3 (PS)
	GamepadLStickLeft   = 647, // [Analog]                                         // Move Window (in Windowing mode)
	GamepadLStickRight  = 648, // [Analog]                                         // Move Window (in Windowing mode)
	GamepadLStickUp     = 649, // [Analog]                                         // Move Window (in Windowing mode)
	GamepadLStickDown   = 650, // [Analog]                                         // Move Window (in Windowing mode)
	GamepadRStickLeft   = 651, // [Analog]
	GamepadRStickRight  = 652, // [Analog]
	GamepadRStickUp     = 653, // [Analog]
	GamepadRStickDown   = 654, // [Analog]
	MouseLeft           = 655,
	MouseRight          = 656,
	MouseMiddle         = 657,
	MouseX1             = 658,
	MouseX2             = 659,
	MouseWheelX         = 660,
	MouseWheelY         = 661,
	ReservedForModCtrl  = 662,
	ReservedForModShift = 663,
	ReservedForModAlt   = 664,
	ReservedForModSuper = 665,
}

KEY_NAMED_KEY_BEGIN :: 512
KEY_NAMED_KEY_END :: 666
KEY_NAMED_KEY_COUNT :: 154
KEY_MOD_NONE :: 0
KEY_MOD_CTRL :: 4096
KEY_MOD_SHIFT :: 8192
KEY_MOD_ALT :: 16384
KEY_MOD_SUPER :: 32768
KEY_MOD_MASK :: 61440

// Flags for Shortcut(), SetNextItemShortcut(),
// (and for upcoming extended versions of IsKeyPressed(), IsMouseClicked(), Shortcut(), SetKeyOwner(), SetItemKeyOwner() that are still in imgui_internal.h)
// Don't mistake with ImGuiInputTextFlags! (which is for ImGui::InputText() function)
InputFlags :: bit_set[InputFlag;i32]
InputFlag :: enum i32 {
	Repeat               = 0, // Enable repeat. Return true on successive repeats. Default for legacy IsKeyPressed(). NOT Default for legacy IsMouseClicked(). MUST BE == 1.
	RouteActive          = 10, // Route to active item only.
	RouteFocused         = 11, // Route to windows in the focus stack (DEFAULT). Deep-most focused window takes inputs. Active item takes inputs over deep-most focused window.
	RouteGlobal          = 12, // Global route (unless a focused window or active item registered the route).
	RouteAlways          = 13, // Do not register route, poll keys directly.
	RouteOverFocused     = 14, // Option: global route: higher priority than focused route (unless active item in focused route).
	RouteOverActive      = 15, // Option: global route: higher priority than active item. Unlikely you need to use that: will interfere with every active items, e.g. CTRL+A registered by InputText will be overridden by this. May not be fully honored as user/internal code is likely to always assume they can access keys when active.
	RouteUnlessBgFocused = 16, // Option: global route: will not be applied if underlying background/void is focused (== no Dear ImGui windows are focused). Useful for overlay applications.
	RouteFromRootWindow  = 17, // Option: route evaluated from the point of view of root window rather than current window.
	Tooltip              = 18, // Automatically display a tooltip when hovering item [BETA] Unsure of right api (opt-in/opt-out)
}

// Configuration flags stored in io.ConfigFlags. Set by user/application.
ConfigFlags :: bit_set[ConfigFlag;i32]
ConfigFlag :: enum i32 {
	NavEnableKeyboard   = 0, // Master keyboard navigation enable flag. Enable full Tabbing + directional arrows + space/enter to activate.
	NavEnableGamepad    = 1, // Master gamepad navigation enable flag. Backend also needs to set ImGuiBackendFlags_HasGamepad.
	NoMouse             = 4, // Instruct dear imgui to disable mouse inputs and interactions.
	NoMouseCursorChange = 5, // Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.
	NoKeyboard          = 6, // Instruct dear imgui to disable keyboard inputs and interactions. This is done by ignoring keyboard events and clearing existing states.
	IsSRGB              = 20, // Application is SRGB-aware.
	IsTouchScreen       = 21, // Application is using a touch screen instead of a mouse.
}

// Backend capabilities flags stored in io.BackendFlags. Set by imgui_impl_xxx or custom backend.
BackendFlags :: bit_set[BackendFlag;i32]
BackendFlag :: enum i32 {
	HasGamepad           = 0, // Backend Platform supports gamepad and currently has one connected.
	HasMouseCursors      = 1, // Backend Platform supports honoring GetMouseCursor() value to change the OS cursor shape.
	HasSetMousePos       = 2, // Backend Platform supports io.WantSetMousePos requests to reposition the OS mouse position (only used if io.ConfigNavMoveSetMousePos is set).
	RendererHasVtxOffset = 3, // Backend Renderer supports ImDrawCmd::VtxOffset. This enables output of large meshes (64K+ vertices) while still using 16-bit indices.
}

// Enumeration for PushStyleColor() / PopStyleColor()
Col :: enum i32 {
	Text                      = 0,
	TextDisabled              = 1,
	WindowBg                  = 2, // Background of normal windows
	ChildBg                   = 3, // Background of child windows
	PopupBg                   = 4, // Background of popups, menus, tooltips windows
	Border                    = 5,
	BorderShadow              = 6,
	FrameBg                   = 7, // Background of checkbox, radio button, plot, slider, text input
	FrameBgHovered            = 8,
	FrameBgActive             = 9,
	TitleBg                   = 10, // Title bar
	TitleBgActive             = 11, // Title bar when focused
	TitleBgCollapsed          = 12, // Title bar when collapsed
	MenuBarBg                 = 13,
	ScrollbarBg               = 14,
	ScrollbarGrab             = 15,
	ScrollbarGrabHovered      = 16,
	ScrollbarGrabActive       = 17,
	CheckMark                 = 18, // Checkbox tick and RadioButton circle
	SliderGrab                = 19,
	SliderGrabActive          = 20,
	Button                    = 21,
	ButtonHovered             = 22,
	ButtonActive              = 23,
	Header                    = 24, // Header* colors are used for CollapsingHeader, TreeNode, Selectable, MenuItem
	HeaderHovered             = 25,
	HeaderActive              = 26,
	Separator                 = 27,
	SeparatorHovered          = 28,
	SeparatorActive           = 29,
	ResizeGrip                = 30, // Resize grip in lower-right and lower-left corners of windows.
	ResizeGripHovered         = 31,
	ResizeGripActive          = 32,
	TabHovered                = 33, // Tab background, when hovered
	Tab                       = 34, // Tab background, when tab-bar is focused & tab is unselected
	TabSelected               = 35, // Tab background, when tab-bar is focused & tab is selected
	TabSelectedOverline       = 36, // Tab horizontal overline, when tab-bar is focused & tab is selected
	TabDimmed                 = 37, // Tab background, when tab-bar is unfocused & tab is unselected
	TabDimmedSelected         = 38, // Tab background, when tab-bar is unfocused & tab is selected
	TabDimmedSelectedOverline = 39, //..horizontal overline, when tab-bar is unfocused & tab is selected
	PlotLines                 = 40,
	PlotLinesHovered          = 41,
	PlotHistogram             = 42,
	PlotHistogramHovered      = 43,
	TableHeaderBg             = 44, // Table header background
	TableBorderStrong         = 45, // Table outer and header borders (prefer using Alpha=1.0 here)
	TableBorderLight          = 46, // Table inner borders (prefer using Alpha=1.0 here)
	TableRowBg                = 47, // Table row background (even rows)
	TableRowBgAlt             = 48, // Table row background (odd rows)
	TextLink                  = 49, // Hyperlink color
	TextSelectedBg            = 50,
	DragDropTarget            = 51, // Rectangle highlighting a drop target
	NavCursor                 = 52, // Color of keyboard/gamepad navigation cursor/rectangle, when visible
	NavWindowingHighlight     = 53, // Highlight window when using CTRL+TAB
	NavWindowingDimBg         = 54, // Darken/colorize entire screen behind the CTRL+TAB window list, when active
	ModalWindowDimBg          = 55, // Darken/colorize entire screen behind a modal window, when one is active
}

COL_COUNT :: 56

// Enumeration for PushStyleVar() / PopStyleVar() to temporarily modify the ImGuiStyle structure.
// - The enum only refers to fields of ImGuiStyle which makes sense to be pushed/popped inside UI code.
//   During initialization or between frames, feel free to just poke into ImGuiStyle directly.
// - Tip: Use your programming IDE navigation facilities on the names in the _second column_ below to find the actual members and their description.
//   - In Visual Studio: CTRL+comma ("Edit.GoToAll") can follow symbols inside comments, whereas CTRL+F12 ("Edit.GoToImplementation") cannot.
//   - In Visual Studio w/ Visual Assist installed: ALT+G ("VAssistX.GoToImplementation") can also follow symbols inside comments.
//   - In VS Code, CLion, etc.: CTRL+click can follow symbols inside comments.
// - When changing this enum, you need to update the associated internal table GStyleVarInfo[] accordingly. This is where we link enum values to members offset/type.
StyleVar :: enum i32 {
	Alpha                       = 0, // float     Alpha
	DisabledAlpha               = 1, // float     DisabledAlpha
	WindowPadding               = 2, // ImVec2    WindowPadding
	WindowRounding              = 3, // float     WindowRounding
	WindowBorderSize            = 4, // float     WindowBorderSize
	WindowMinSize               = 5, // ImVec2    WindowMinSize
	WindowTitleAlign            = 6, // ImVec2    WindowTitleAlign
	ChildRounding               = 7, // float     ChildRounding
	ChildBorderSize             = 8, // float     ChildBorderSize
	PopupRounding               = 9, // float     PopupRounding
	PopupBorderSize             = 10, // float     PopupBorderSize
	FramePadding                = 11, // ImVec2    FramePadding
	FrameRounding               = 12, // float     FrameRounding
	FrameBorderSize             = 13, // float     FrameBorderSize
	ItemSpacing                 = 14, // ImVec2    ItemSpacing
	ItemInnerSpacing            = 15, // ImVec2    ItemInnerSpacing
	IndentSpacing               = 16, // float     IndentSpacing
	CellPadding                 = 17, // ImVec2    CellPadding
	ScrollbarSize               = 18, // float     ScrollbarSize
	ScrollbarRounding           = 19, // float     ScrollbarRounding
	GrabMinSize                 = 20, // float     GrabMinSize
	GrabRounding                = 21, // float     GrabRounding
	TabRounding                 = 22, // float     TabRounding
	TabBorderSize               = 23, // float     TabBorderSize
	TabBarBorderSize            = 24, // float     TabBarBorderSize
	TabBarOverlineSize          = 25, // float     TabBarOverlineSize
	TableAngledHeadersAngle     = 26, // float     TableAngledHeadersAngle
	TableAngledHeadersTextAlign = 27, // ImVec2  TableAngledHeadersTextAlign
	ButtonTextAlign             = 28, // ImVec2    ButtonTextAlign
	SelectableTextAlign         = 29, // ImVec2    SelectableTextAlign
	SeparatorTextBorderSize     = 30, // float     SeparatorTextBorderSize
	SeparatorTextAlign          = 31, // ImVec2    SeparatorTextAlign
	SeparatorTextPadding        = 32, // ImVec2    SeparatorTextPadding
}

STYLE_VAR_COUNT :: 33

// Flags for InvisibleButton() [extended in imgui_internal.h]
ButtonFlags :: bit_set[ButtonFlag;i32]
ButtonFlag :: enum i32 {
	MouseButtonLeft   = 0, // React on left mouse button (default)
	MouseButtonRight  = 1, // React on right mouse button
	MouseButtonMiddle = 2, // React on center mouse button
	EnableNav         = 3, // InvisibleButton(): do not disable navigation/tabbing. Otherwise disabled by default.
}

// Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
ColorEditFlags :: bit_set[ColorEditFlag;i32]
ColorEditFlag :: enum i32 {
	NoAlpha          = 1, //              // ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
	NoPicker         = 2, //              // ColorEdit: disable picker when clicking on color square.
	NoOptions        = 3, //              // ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
	NoSmallPreview   = 4, //              // ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
	NoInputs         = 5, //              // ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
	NoTooltip        = 6, //              // ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
	NoLabel          = 7, //              // ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
	NoSidePreview    = 8, //              // ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
	NoDragDrop       = 9, //              // ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
	NoBorder         = 10, //              // ColorButton: disable border (which is enforced by default)
	AlphaBar         = 16, //              // ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
	AlphaPreview     = 17, //              // ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
	AlphaPreviewHalf = 18, //              // ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
	HDR              = 19, //              // (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags_Float flag as well).
	DisplayRGB       = 20, // [Display]    // ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
	DisplayHSV       = 21, // [Display]    // "
	DisplayHex       = 22, // [Display]    // "
	Uint8            = 23, // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
	Float            = 24, // [DataType]   // ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
	PickerHueBar     = 25, // [Picker]     // ColorPicker: bar for Hue, rectangle for Sat/Value.
	PickerHueWheel   = 26, // [Picker]     // ColorPicker: wheel for Hue, triangle for Sat/Value.
	InputRGB         = 27, // [Input]      // ColorEdit, ColorPicker: input and output data in RGB format.
	InputHSV         = 28, // [Input]      // ColorEdit, ColorPicker: input and output data in HSV format.
}

// Flags for DragFloat(), DragInt(), SliderFloat(), SliderInt() etc.
// We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
// (Those are per-item flags. There is shared behavior flag too: ImGuiIO: io.ConfigDragClickToInputText)
SliderFlags :: bit_set[SliderFlag;i32]
SliderFlag :: enum i32 {
	Logarithmic     = 5, // Make the widget logarithmic (linear otherwise). Consider using ImGuiSliderFlags_NoRoundToFormat with this if using a format-string with small amount of digits.
	NoRoundToFormat = 6, // Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
	NoInput         = 7, // Disable CTRL+Click or Enter key allowing to input text directly into the widget.
	WrapAround      = 8, // Enable wrapping around from max to min and from min to max. Only supported by DragXXX() functions for now.
	ClampOnInput    = 9, // Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.
	ClampZeroRange  = 10, // Clamp even if min==max==0.0f. Otherwise due to legacy reason DragXXX functions don't clamp with those values. When your clamping limits are dynamic you almost always want to use it.
}

SLIDER_FLAGS_ALWAYS_CLAMP :: SliderFlags{.ClampOnInput, .ClampZeroRange}

// Identify a mouse button.
// Those values are guaranteed to be stable and we frequently use 0/1 directly. Named enums provided for convenience.
MouseButton :: enum i32 {
	Left   = 0,
	Right  = 1,
	Middle = 2,
}

MOUSE_BUTTON_COUNT :: 5

// Enumeration for GetMouseCursor()
// User code may request backend to display given cursor by calling SetMouseCursor(), which is why we have some cursors that are marked unused here
MouseCursor :: enum i32 {
	None       = -1,
	Arrow      = 0,
	TextInput  = 1, // When hovering over InputText, etc.
	ResizeAll  = 2, // (Unused by Dear ImGui functions)
	ResizeNS   = 3, // When hovering over a horizontal border
	ResizeEW   = 4, // When hovering over a vertical border or a column
	ResizeNESW = 5, // When hovering over the bottom-left corner of a window
	ResizeNWSE = 6, // When hovering over the bottom-right corner of a window
	Hand       = 7, // (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
	NotAllowed = 8, // When hovering something with disallowed interaction. Usually a crossed circle.
}

MOUSE_CURSOR_COUNT :: 9

// Enumeration for AddMouseSourceEvent() actual source of Mouse Input data.
// Historically we use "Mouse" terminology everywhere to indicate pointer data, e.g. MousePos, IsMousePressed(), io.AddMousePosEvent()
// But that "Mouse" data can come from different source which occasionally may be useful for application to know about.
// You can submit a change of pointer type using io.AddMouseSourceEvent().
MouseSource :: enum i32 {
	Mouse       = 0, // Input is coming from an actual mouse.
	TouchScreen = 1, // Input is coming from a touch screen (no hovering prior to initial press, less precise initial press aiming, dual-axis wheeling possible).
	Pen         = 2, // Input is coming from a pressure/magnetic pen (often used in conjunction with high-sampling rates).
}

MOUSE_SOURCE_COUNT :: 3

// Enumeration for ImGui::SetNextWindow***(), SetWindow***(), SetNextItem***() functions
// Represent a condition.
// Important: Treat as a regular enum! Do NOT combine multiple values using binary operators! All the functions above treat 0 as a shortcut to ImGuiCond_Always.
Cond :: enum i32 {
	None         = 0, // No condition (always set the variable), same as _Always
	Always       = 1, // No condition (always set the variable), same as _None
	Once         = 2, // Set the variable once per runtime session (only the first call will succeed)
	FirstUseEver = 4, // Set the variable if the object/window has no persistently saved data (no entry in .ini file)
	Appearing    = 8, // Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
}

// Flags for ImGui::BeginTable()
// - Important! Sizing policies have complex and subtle side effects, much more so than you would expect.
//   Read comments/demos carefully + experiment with live demos to get acquainted with them.
// - The DEFAULT sizing policies are:
//    - Default to ImGuiTableFlags_SizingFixedFit    if ScrollX is on, or if host window has ImGuiWindowFlags_AlwaysAutoResize.
//    - Default to ImGuiTableFlags_SizingStretchSame if ScrollX is off.
// - When ScrollX is off:
//    - Table defaults to ImGuiTableFlags_SizingStretchSame -> all Columns defaults to ImGuiTableColumnFlags_WidthStretch with same weight.
//    - Columns sizing policy allowed: Stretch (default), Fixed/Auto.
//    - Fixed Columns (if any) will generally obtain their requested width (unless the table cannot fit them all).
//    - Stretch Columns will share the remaining width according to their respective weight.
//    - Mixed Fixed/Stretch columns is possible but has various side-effects on resizing behaviors.
//      The typical use of mixing sizing policies is: any number of LEADING Fixed columns, followed by one or two TRAILING Stretch columns.
//      (this is because the visible order of columns have subtle but necessary effects on how they react to manual resizing).
// - When ScrollX is on:
//    - Table defaults to ImGuiTableFlags_SizingFixedFit -> all Columns defaults to ImGuiTableColumnFlags_WidthFixed
//    - Columns sizing policy allowed: Fixed/Auto mostly.
//    - Fixed Columns can be enlarged as needed. Table will show a horizontal scrollbar if needed.
//    - When using auto-resizing (non-resizable) fixed columns, querying the content width to use item right-alignment e.g. SetNextItemWidth(-FLT_MIN) doesn't make sense, would create a feedback loop.
//    - Using Stretch columns OFTEN DOES NOT MAKE SENSE if ScrollX is on, UNLESS you have specified a value for 'inner_width' in BeginTable().
//      If you specify a value for 'inner_width' then effectively the scrolling space is known and Stretch or mixed Fixed/Stretch columns become meaningful again.
// - Read on documentation at the top of imgui_tables.cpp for details.
TableFlags :: bit_set[TableFlag;i32]
TableFlag :: enum i32 {
	Resizable                  = 0, // Enable resizing columns.
	Reorderable                = 1, // Enable reordering columns in header row (need calling TableSetupColumn() + TableHeadersRow() to display headers)
	Hideable                   = 2, // Enable hiding/disabling columns in context menu.
	Sortable                   = 3, // Enable sorting. Call TableGetSortSpecs() to obtain sort specs. Also see ImGuiTableFlags_SortMulti and ImGuiTableFlags_SortTristate.
	NoSavedSettings            = 4, // Disable persisting columns order, width and sort settings in the .ini file.
	ContextMenuInBody          = 5, // Right-click on columns body/contents will display table context menu. By default it is available in TableHeadersRow().
	RowBg                      = 6, // Set each RowBg color with ImGuiCol_TableRowBg or ImGuiCol_TableRowBgAlt (equivalent of calling TableSetBgColor with ImGuiTableBgFlags_RowBg0 on each row manually)
	BordersInnerH              = 7, // Draw horizontal borders between rows.
	BordersOuterH              = 8, // Draw horizontal borders at the top and bottom.
	BordersInnerV              = 9, // Draw vertical borders between columns.
	BordersOuterV              = 10, // Draw vertical borders on the left and right sides.
	NoBordersInBody            = 11, // [ALPHA] Disable vertical borders in columns Body (borders will always appear in Headers). -> May move to style
	NoBordersInBodyUntilResize = 12, // [ALPHA] Disable vertical borders in columns Body until hovered for resize (borders will always appear in Headers). -> May move to style
	SizingFixedFit             = 13, // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
	SizingFixedSame            = 14, // Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGuiTableFlags_NoKeepColumnsVisible.
	SizingStretchProp          = 13, // Columns default to _WidthStretch with default weights proportional to each columns contents widths.
	SizingStretchSame          = 15, // Columns default to _WidthStretch with default weights all equal, unless overridden by TableSetupColumn().
	NoHostExtendX              = 16, // Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
	NoHostExtendY              = 17, // Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
	NoKeepColumnsVisible       = 18, // Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
	PreciseWidths              = 19, // Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
	NoClip                     = 20, // Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with TableSetupScrollFreeze().
	PadOuterX                  = 21, // Default if BordersOuterV is on. Enable outermost padding. Generally desirable if you have headers.
	NoPadOuterX                = 22, // Default if BordersOuterV is off. Disable outermost padding.
	NoPadInnerX                = 23, // Disable inner padding between columns (double inner padding if BordersOuterV is on, single inner padding if BordersOuterV is off).
	ScrollX                    = 24, // Enable horizontal scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size. Changes default sizing policy. Because this creates a child window, ScrollY is currently generally recommended when using ScrollX.
	ScrollY                    = 25, // Enable vertical scrolling. Require 'outer_size' parameter of BeginTable() to specify the container size.
	SortMulti                  = 26, // Hold shift when clicking headers to sort on multiple column. TableGetSortSpecs() may return specs where (SpecsCount > 1).
	SortTristate               = 27, // Allow no sorting, disable default sorting. TableGetSortSpecs() may return specs where (SpecsCount == 0).
	HighlightHoveredColumn     = 28, // Highlight column headers when hovered (may evolve into a fuller highlight)
}

TABLE_FLAGS_BORDERS_H :: TableFlags{.BordersInnerH, .BordersOuterH}
TABLE_FLAGS_BORDERS_V :: TableFlags{.BordersInnerV, .BordersOuterV}
TABLE_FLAGS_BORDERS_INNER :: TableFlags{.BordersInnerV, .BordersInnerH}
TABLE_FLAGS_BORDERS_OUTER :: TableFlags{.BordersOuterV, .BordersOuterH}
TABLE_FLAGS_BORDERS :: TableFlags{.BordersInnerV, .BordersInnerH, .BordersOuterV, .BordersOuterH}

// Flags for ImGui::TableSetupColumn()
TableColumnFlags :: bit_set[TableColumnFlag;i32]
TableColumnFlag :: enum i32 {
	Disabled             = 0, // Overriding/master disable flag: hide column, won't show in context menu (unlike calling TableSetColumnEnabled() which manipulates the user accessible state)
	DefaultHide          = 1, // Default as a hidden/disabled column.
	DefaultSort          = 2, // Default as a sorting column.
	WidthStretch         = 3, // Column will stretch. Preferable with horizontal scrolling disabled (default if table sizing policy is _SizingStretchSame or _SizingStretchProp).
	WidthFixed           = 4, // Column will not stretch. Preferable with horizontal scrolling enabled (default if table sizing policy is _SizingFixedFit and table is resizable).
	NoResize             = 5, // Disable manual resizing.
	NoReorder            = 6, // Disable manual reordering this column, this will also prevent other columns from crossing over this column.
	NoHide               = 7, // Disable ability to hide/disable this column.
	NoClip               = 8, // Disable clipping for this column (all NoClip columns will render in a same draw command).
	NoSort               = 9, // Disable ability to sort on this field (even if ImGuiTableFlags_Sortable is set on the table).
	NoSortAscending      = 10, // Disable ability to sort in the ascending direction.
	NoSortDescending     = 11, // Disable ability to sort in the descending direction.
	NoHeaderLabel        = 12, // TableHeadersRow() will submit an empty label for this column. Convenient for some small columns. Name will still appear in context menu or in angled headers. You may append into this cell by calling TableSetColumnIndex() right after the TableHeadersRow() call.
	NoHeaderWidth        = 13, // Disable header text width contribution to automatic column width.
	PreferSortAscending  = 14, // Make the initial sort direction Ascending when first sorting on this column (default).
	PreferSortDescending = 15, // Make the initial sort direction Descending when first sorting on this column.
	IndentEnable         = 16, // Use current Indent value when entering cell (default for column 0).
	IndentDisable        = 17, // Ignore current Indent value when entering cell (default for columns > 0). Indentation changes _within_ the cell will still be honored.
	AngledHeader         = 18, // TableHeadersRow() will submit an angled header row for this column. Note this will add an extra row.
	IsEnabled            = 24, // Status: is enabled == not hidden by user/api (referred to as "Hide" in _DefaultHide and _NoHide) flags.
	IsVisible            = 25, // Status: is visible == is enabled AND not clipped by scrolling.
	IsSorted             = 26, // Status: is currently part of the sort specs
	IsHovered            = 27, // Status: is hovered by mouse
}

// Flags for ImGui::TableNextRow()
TableRowFlags :: bit_set[TableRowFlag;i32]
TableRowFlag :: enum i32 {
	Headers = 0, // Identify header row (set default background color + width of its contents accounted differently for auto column width)
}

// Enum for ImGui::TableSetBgColor()
// Background colors are rendering in 3 layers:
//  - Layer 0: draw with RowBg0 color if set, otherwise draw with ColumnBg0 if set.
//  - Layer 1: draw with RowBg1 color if set, otherwise draw with ColumnBg1 if set.
//  - Layer 2: draw with CellBg color if set.
// The purpose of the two row/columns layers is to let you decide if a background color change should override or blend with the existing color.
// When using ImGuiTableFlags_RowBg on the table, each row has the RowBg0 color automatically set for odd/even rows.
// If you set the color of RowBg0 target, your color will override the existing RowBg0 color.
// If you set the color of RowBg1 or ColumnBg1 target, your color will blend over the RowBg0 color.
TableBgTarget :: enum i32 {
	None   = 0,
	RowBg0 = 1, // Set row background color 0 (generally used for background, automatically set when ImGuiTableFlags_RowBg is used)
	RowBg1 = 2, // Set row background color 1 (generally used for selection marking)
	CellBg = 3, // Set cell background color (top-most color)
}

// Flags for BeginMultiSelect()
MultiSelectFlags :: bit_set[MultiSelectFlag;i32]
MultiSelectFlag :: enum i32 {
	SingleSelect          = 0, // Disable selecting more than one item. This is available to allow single-selection code to share same code/logic if desired. It essentially disables the main purpose of BeginMultiSelect() tho!
	NoSelectAll           = 1, // Disable CTRL+A shortcut to select all.
	NoRangeSelect         = 2, // Disable Shift+selection mouse/keyboard support (useful for unordered 2D selection). With BoxSelect is also ensure contiguous SetRange requests are not combined into one. This allows not handling interpolation in SetRange requests.
	NoAutoSelect          = 3, // Disable selecting items when navigating (useful for e.g. supporting range-select in a list of checkboxes).
	NoAutoClear           = 4, // Disable clearing selection when navigating or selecting another one (generally used with ImGuiMultiSelectFlags_NoAutoSelect. useful for e.g. supporting range-select in a list of checkboxes).
	NoAutoClearOnReselect = 5, // Disable clearing selection when clicking/selecting an already selected item.
	BoxSelect1d           = 6, // Enable box-selection with same width and same x pos items (e.g. full row Selectable()). Box-selection works better with little bit of spacing between items hit-box in order to be able to aim at empty space.
	BoxSelect2d           = 7, // Enable box-selection with varying width or varying x pos items support (e.g. different width labels, or 2D layout/grid). This is slower: alters clipping logic so that e.g. horizontal movements will update selection of normally clipped items.
	BoxSelectNoScroll     = 8, // Disable scrolling when box-selecting near edges of scope.
	ClearOnEscape         = 9, // Clear selection when pressing Escape while scope is focused.
	ClearOnClickVoid      = 10, // Clear selection when clicking on empty location within scope.
	ScopeWindow           = 11, // Scope for _BoxSelect and _ClearOnClickVoid is whole window (Default). Use if BeginMultiSelect() covers a whole window or used a single time in same window.
	ScopeRect             = 12, // Scope for _BoxSelect and _ClearOnClickVoid is rectangle encompassing BeginMultiSelect()/EndMultiSelect(). Use if BeginMultiSelect() is called multiple times in same window.
	SelectOnClick         = 13, // Apply selection on mouse down when clicking on unselected item. (Default)
	SelectOnClickRelease  = 14, // Apply selection on mouse release when clicking an unselected item. Allow dragging an unselected item without altering selection.
	NavWrapX              = 16, // [Temporary] Enable navigation wrapping on X axis. Provided as a convenience because we don't have a design for the general Nav API for this yet. When the more general feature be public we may obsolete this flag in favor of new one.
}

// Selection request type
SelectionRequestType :: enum i32 {
	None     = 0,
	SetAll   = 1, // Request app to clear selection (if Selected==false) or select all items (if Selected==true). We cannot set RangeFirstItem/RangeLastItem as its contents is entirely up to user (not necessarily an index)
	SetRange = 2, // Request app to select/unselect [RangeFirstItem..RangeLastItem] items (inclusive) based on value of Selected. Only EndMultiSelect() request this, app code can read after BeginMultiSelect() and it will always be false.
}

// Flags for ImDrawList functions
// (Legacy: bit 0 must always correspond to ImDrawFlags_Closed to be backward compatible with old API using a bool. Bits 1..3 must be unused)
DrawFlags :: bit_set[DrawFlag;i32]
DrawFlag :: enum i32 {
	Closed                  = 0, // PathStroke(), AddPolyline(): specify that shape should be closed (Important: this is always == 1 for legacy reason)
	RoundCornersTopLeft     = 4, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-left corner only (when rounding > 0.0f, we default to all corners). Was 0x01.
	RoundCornersTopRight    = 5, // AddRect(), AddRectFilled(), PathRect(): enable rounding top-right corner only (when rounding > 0.0f, we default to all corners). Was 0x02.
	RoundCornersBottomLeft  = 6, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-left corner only (when rounding > 0.0f, we default to all corners). Was 0x04.
	RoundCornersBottomRight = 7, // AddRect(), AddRectFilled(), PathRect(): enable rounding bottom-right corner only (when rounding > 0.0f, we default to all corners). Wax 0x08.
	RoundCornersNone        = 8, // AddRect(), AddRectFilled(), PathRect(): disable rounding on all corners (when rounding > 0.0f). This is NOT zero, NOT an implicit flag!
}

DRAW_FLAGS_ROUND_CORNERS_TOP :: DrawFlags{.RoundCornersTopLeft, .RoundCornersTopRight}
DRAW_FLAGS_ROUND_CORNERS_BOTTOM :: DrawFlags{.RoundCornersBottomLeft, .RoundCornersBottomRight}
DRAW_FLAGS_ROUND_CORNERS_LEFT :: DrawFlags{.RoundCornersBottomLeft, .RoundCornersTopLeft}
DRAW_FLAGS_ROUND_CORNERS_RIGHT :: DrawFlags{.RoundCornersBottomRight, .RoundCornersTopRight}
DRAW_FLAGS_ROUND_CORNERS_ALL :: DrawFlags {
	.RoundCornersTopLeft,
	.RoundCornersTopRight,
	.RoundCornersBottomLeft,
	.RoundCornersBottomRight,
}

// Flags for ImDrawList instance. Those are set automatically by ImGui:: functions from ImGuiIO settings, and generally not manipulated directly.
// It is however possible to temporarily alter flags between calls to ImDrawList:: functions.
DrawListFlags :: bit_set[DrawListFlag;i32]
DrawListFlag :: enum i32 {
	AntiAliasedLines       = 0, // Enable anti-aliased lines/borders (*2 the number of triangles for 1.0f wide line or lines thin enough to be drawn using textures, otherwise *3 the number of triangles)
	AntiAliasedLinesUseTex = 1, // Enable anti-aliased lines/borders using textures when possible. Require backend to render with bilinear filtering (NOT point/nearest filtering).
	AntiAliasedFill        = 2, // Enable anti-aliased edge around filled shapes (rounded rectangles, circles).
	AllowVtxOffset         = 3, // Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags_RendererHasVtxOffset' is enabled.
}

// Flags for ImFontAtlas build
FontAtlasFlags :: bit_set[FontAtlasFlag;i32]
FontAtlasFlag :: enum i32 {
	NoPowerOfTwoHeight = 0, // Don't round the height to next power of two
	NoMouseCursors     = 1, // Don't build software mouse cursors into the atlas (save a little texture memory)
	NoBakedLines       = 2, // Don't build thick line textures into the atlas (save a little texture memory, allow support for point/nearest filtering). The AntiAliasedLinesUseTex features uses them, otherwise they will be rendered using polygons (more expensive for CPU/GPU).
}

// Flags stored in ImGuiViewport::Flags, giving indications to the platform backends.
ViewportFlags :: bit_set[ViewportFlag;i32]
ViewportFlag :: enum i32 {
	IsPlatformWindow  = 0, // Represent a Platform Window
	IsPlatformMonitor = 1, // Represent a Platform Monitor (unused yet)
	OwnedByApp        = 2, // Platform Window: Is created/managed by the application (rather than a dear imgui backend)
}

ID :: u32
KeyChord :: i32
TextureID :: u64
DrawIdx :: u16
Wchar32 :: u32
Wchar16 :: u16
Wchar :: Wchar32
SelectionUserData :: i64
InputTextCallback :: #type proc(data: ^InputTextCallbackData) -> i32
SizeCallback :: #type proc(data: ^SizeCallbackData)
MemAllocFunc :: #type proc(sz: uint, user_data: rawptr) -> rawptr
MemFreeFunc :: #type proc(ptr: rawptr, user_data: rawptr)
DrawCallback :: #type proc(parent_list: ^DrawList, cmd: ^DrawCmd)

DrawListSharedData :: struct {}

FontBuilderIO :: struct {}

Context :: struct {}

Vec2 :: struct {
	x: f32,
	y: f32,
}

Vec4 :: struct {
	x: f32,
	y: f32,
	z: f32,
	w: f32,
}

TableSortSpecs :: struct {
	specs:       ^TableColumnSortSpecs,
	specs_count: i32,
	specs_dirty: bool,
}

TableColumnSortSpecs :: struct {
	column_user_id: ID,
	column_index:   i16,
	sort_order:     i16,
	sort_direction: SortDirection,
}

VectorWchar :: struct {
	size:     i32,
	capacity: i32,
	data:     cstring,
}

VectorTextFilterTextRange :: struct {
	size:     i32,
	capacity: i32,
	data:     ^TextFilterTextRange,
}

VectorChar :: struct {
	size:     i32,
	capacity: i32,
	data:     cstring,
}

VectorStoragePair :: struct {
	size:     i32,
	capacity: i32,
	data:     ^StoragePair,
}

VectorSelectionRequest :: struct {
	size:     i32,
	capacity: i32,
	data:     ^SelectionRequest,
}

VectorDrawCmd :: struct {
	size:     i32,
	capacity: i32,
	data:     ^DrawCmd,
}

VectorDrawIdx :: struct {
	size:     i32,
	capacity: i32,
	data:     ^DrawIdx,
}

VectorDrawChannel :: struct {
	size:     i32,
	capacity: i32,
	data:     ^DrawChannel,
}

VectorDrawVert :: struct {
	size:     i32,
	capacity: i32,
	data:     ^DrawVert,
}

VectorVec2 :: struct {
	size:     i32,
	capacity: i32,
	data:     ^Vec2,
}

VectorVec4 :: struct {
	size:     i32,
	capacity: i32,
	data:     ^Vec4,
}

VectorTextureID :: struct {
	size:     i32,
	capacity: i32,
	data:     ^TextureID,
}

VectorU8 :: struct {
	size:     i32,
	capacity: i32,
	data:     ^u8,
}

VectorDrawListPtr :: struct {
	size:     i32,
	capacity: i32,
	data:     ^^DrawList,
}

VectorU32 :: struct {
	size:     i32,
	capacity: i32,
	data:     ^u32,
}

VectorFontPtr :: struct {
	size:     i32,
	capacity: i32,
	data:     ^^Font,
}

VectorFontAtlasCustomRect :: struct {
	size:     i32,
	capacity: i32,
	data:     ^FontAtlasCustomRect,
}

VectorFontConfig :: struct {
	size:     i32,
	capacity: i32,
	data:     ^FontConfig,
}

VectorFloat :: struct {
	size:     i32,
	capacity: i32,
	data:     ^f32,
}

VectorFontGlyph :: struct {
	size:     i32,
	capacity: i32,
	data:     ^FontGlyph,
}

Style :: struct {
	alpha:                           f32,
	disabled_alpha:                  f32,
	window_padding:                  Vec2,
	window_rounding:                 f32,
	window_border_size:              f32,
	window_min_size:                 Vec2,
	window_title_align:              Vec2,
	window_menu_button_position:     Dir,
	child_rounding:                  f32,
	child_border_size:               f32,
	popup_rounding:                  f32,
	popup_border_size:               f32,
	frame_padding:                   Vec2,
	frame_rounding:                  f32,
	frame_border_size:               f32,
	item_spacing:                    Vec2,
	item_inner_spacing:              Vec2,
	cell_padding:                    Vec2,
	touch_extra_padding:             Vec2,
	indent_spacing:                  f32,
	columns_min_spacing:             f32,
	scrollbar_size:                  f32,
	scrollbar_rounding:              f32,
	grab_min_size:                   f32,
	grab_rounding:                   f32,
	log_slider_deadzone:             f32,
	tab_rounding:                    f32,
	tab_border_size:                 f32,
	tab_min_width_for_close_button:  f32,
	tab_bar_border_size:             f32,
	tab_bar_overline_size:           f32,
	table_angled_headers_angle:      f32,
	table_angled_headers_text_align: Vec2,
	color_button_position:           Dir,
	button_text_align:               Vec2,
	selectable_text_align:           Vec2,
	separator_text_border_size:      f32,
	separator_text_align:            Vec2,
	separator_text_padding:          Vec2,
	display_window_padding:          Vec2,
	display_safe_area_padding:       Vec2,
	mouse_cursor_scale:              f32,
	anti_aliased_lines:              bool,
	anti_aliased_lines_use_tex:      bool,
	anti_aliased_fill:               bool,
	curve_tessellation_tol:          f32,
	circle_tessellation_max_error:   f32,
	colors:                          [COL_COUNT]Vec4,
	hover_stationary_delay:          f32,
	hover_delay_short:               f32,
	hover_delay_normal:              f32,
	hover_flags_for_tooltip_mouse:   HoveredFlags,
	hover_flags_for_tooltip_nav:     HoveredFlags,
}

KeyData :: struct {
	down:               bool,
	down_duration:      f32,
	down_duration_prev: f32,
	analog_value:       f32,
}

IO :: struct {
	config_flags:                             ConfigFlags,
	backend_flags:                            BackendFlags,
	display_size:                             Vec2,
	delta_time:                               f32,
	ini_saving_rate:                          f32,
	ini_filename:                             cstring,
	log_filename:                             cstring,
	user_data:                                rawptr,
	fonts:                                    ^FontAtlas,
	font_global_scale:                        f32,
	font_allow_user_scaling:                  bool,
	font_default:                             ^Font,
	display_framebuffer_scale:                Vec2,
	config_nav_swap_gamepad_buttons:          bool,
	config_nav_move_set_mouse_pos:            bool,
	config_nav_capture_keyboard:              bool,
	config_nav_escape_clear_focus_item:       bool,
	config_nav_escape_clear_focus_window:     bool,
	config_nav_cursor_visible_auto:           bool,
	config_nav_cursor_visible_always:         bool,
	mouse_draw_cursor:                        bool,
	config_mac_osx_behaviors:                 bool,
	config_input_trickle_event_queue:         bool,
	config_input_text_cursor_blink:           bool,
	config_input_text_enter_keep_active:      bool,
	config_drag_click_to_input_text:          bool,
	config_windows_resize_from_edges:         bool,
	config_windows_move_from_title_bar_only:  bool,
	config_windows_copy_contents_with_ctrl_c: bool,
	config_scrollbar_scroll_by_page:          bool,
	config_memory_compact_timer:              f32,
	mouse_double_click_time:                  f32,
	mouse_double_click_max_dist:              f32,
	mouse_drag_threshold:                     f32,
	key_repeat_delay:                         f32,
	key_repeat_rate:                          f32,
	config_error_recovery:                    bool,
	config_error_recovery_enable_assert:      bool,
	config_error_recovery_enable_debug_log:   bool,
	config_error_recovery_enable_tooltip:     bool,
	config_debug_is_debugger_present:         bool,
	config_debug_highlight_id_conflicts:      bool,
	config_debug_begin_return_value_once:     bool,
	config_debug_begin_return_value_loop:     bool,
	config_debug_ignore_focus_loss:           bool,
	config_debug_ini_settings:                bool,
	backend_platform_name:                    cstring,
	backend_renderer_name:                    cstring,
	backend_platform_user_data:               rawptr,
	backend_renderer_user_data:               rawptr,
	backend_language_user_data:               rawptr,
	want_capture_mouse:                       bool,
	want_capture_keyboard:                    bool,
	want_text_input:                          bool,
	want_set_mouse_pos:                       bool,
	want_save_ini_settings:                   bool,
	nav_active:                               bool,
	nav_visible:                              bool,
	framerate:                                f32,
	metrics_render_vertices:                  i32,
	metrics_render_indices:                   i32,
	metrics_render_windows:                   i32,
	metrics_active_windows:                   i32,
	mouse_delta:                              Vec2,
	ctx:                                      ^Context,
	mouse_pos:                                Vec2,
	mouse_down:                               [5]bool,
	mouse_wheel:                              f32,
	mouse_wheel_h:                            f32,
	mouse_source:                             MouseSource,
	key_ctrl:                                 bool,
	key_shift:                                bool,
	key_alt:                                  bool,
	key_super:                                bool,
	key_mods:                                 KeyChord,
	keys_data:                                [KEY_NAMED_KEY_COUNT]KeyData,
	want_capture_mouse_unless_popup_close:    bool,
	mouse_pos_prev:                           Vec2,
	mouse_clicked_pos:                        [5]Vec2,
	mouse_clicked_time:                       [5]f64,
	mouse_clicked:                            [5]bool,
	mouse_double_clicked:                     [5]bool,
	mouse_clicked_count:                      [5]u16,
	mouse_clicked_last_count:                 [5]u16,
	mouse_released:                           [5]bool,
	mouse_down_owned:                         [5]bool,
	mouse_down_owned_unless_popup_close:      [5]bool,
	mouse_wheel_request_axis_swap:            bool,
	mouse_ctrl_left_as_right_click:           bool,
	mouse_down_duration:                      [5]f32,
	mouse_down_duration_prev:                 [5]f32,
	mouse_drag_max_distance_sqr:              [5]f32,
	pen_pressure:                             f32,
	app_focus_lost:                           bool,
	app_accepting_events:                     bool,
	input_queue_surrogate:                    Wchar16,
	input_queue_characters:                   VectorWchar,
	get_clipboard_text_fn:                    proc(user_data: rawptr) -> cstring,
	set_clipboard_text_fn:                    proc(user_data: rawptr, text: cstring),
	clipboard_user_data:                      rawptr,
}

InputTextCallbackData :: struct {
	ctx:             ^Context,
	event_flag:      InputTextFlags,
	flags:           InputTextFlags,
	user_data:       rawptr,
	event_char:      Wchar,
	event_key:       Key,
	buf:             cstring,
	buf_text_len:    i32,
	buf_size:        i32,
	buf_dirty:       bool,
	cursor_pos:      i32,
	selection_start: i32,
	selection_end:   i32,
}

SizeCallbackData :: struct {
	user_data:    rawptr,
	pos:          Vec2,
	current_size: Vec2,
	desired_size: Vec2,
}

Payload :: struct {
	data:             rawptr,
	data_size:        i32,
	source_id:        ID,
	source_parent_id: ID,
	data_frame_count: i32,
	data_type:        [32 + 1]u8,
	preview:          bool,
	delivery:         bool,
}

TextFilterTextRange :: struct {
	b: cstring,
	e: cstring,
}

TextFilter :: struct {
	input_buf:  [256]u8,
	filters:    VectorTextFilterTextRange,
	count_grep: i32,
}

TextBuffer :: struct {
	buf: VectorChar,
}

StoragePair :: struct {
	key:              ID,
	_anonymous_type0: AnonymousType0,
}

AnonymousType0 :: struct {
	val_i: i32,
	val_f: f32,
	val_p: rawptr,
}

Storage :: struct {
	data: VectorStoragePair,
}

ListClipper :: struct {
	ctx:                 ^Context,
	display_start:       i32,
	display_end:         i32,
	items_count:         i32,
	items_height:        f32,
	start_pos_y:         f32,
	start_seek_offset_y: f64,
	temp_data:           rawptr,
}

Color :: struct {
	value: Vec4,
}

MultiSelectIO :: struct {
	requests:        VectorSelectionRequest,
	range_src_item:  SelectionUserData,
	nav_id_item:     SelectionUserData,
	nav_id_selected: bool,
	range_src_reset: bool,
	items_count:     i32,
}

SelectionRequest :: struct {
	type:             SelectionRequestType,
	selected:         bool,
	range_direction:  i8,
	range_first_item: SelectionUserData,
	range_last_item:  SelectionUserData,
}

SelectionBasicStorage :: struct {
	size:                        i32,
	preserve_order:              bool,
	user_data:                   rawptr,
	adapter_index_to_storage_id: proc(self: ^SelectionBasicStorage, idx: i32) -> ID,
	_selection_order:            i32,
	_storage:                    Storage,
}

SelectionExternalStorage :: struct {
	user_data:                 rawptr,
	adapter_set_item_selected: proc(self: ^SelectionExternalStorage, idx: i32, selected: bool),
}

DrawCmd :: struct {
	clip_rect:                 Vec4,
	texture_id:                TextureID,
	vtx_offset:                u32,
	idx_offset:                u32,
	elem_count:                u32,
	user_callback:             DrawCallback,
	user_callback_data:        rawptr,
	user_callback_data_size:   i32,
	user_callback_data_offset: i32,
}

DrawVert :: struct {
	pos: Vec2,
	uv:  Vec2,
	col: u32,
}

DrawCmdHeader :: struct {
	clip_rect:  Vec4,
	texture_id: TextureID,
	vtx_offset: u32,
}

DrawChannel :: struct {
	_cmd_buffer: VectorDrawCmd,
	_idx_buffer: VectorDrawIdx,
}

DrawListSplitter :: struct {
	_current:  i32,
	_count:    i32,
	_channels: VectorDrawChannel,
}

DrawList :: struct {
	cmd_buffer:          VectorDrawCmd,
	idx_buffer:          VectorDrawIdx,
	vtx_buffer:          VectorDrawVert,
	flags:               DrawListFlags,
	_vtx_current_idx:    u32,
	_data:               ^DrawListSharedData,
	_vtx_write_ptr:      ^DrawVert,
	_idx_write_ptr:      ^DrawIdx,
	_path:               VectorVec2,
	_cmd_header:         DrawCmdHeader,
	_splitter:           DrawListSplitter,
	_clip_rect_stack:    VectorVec4,
	_texture_id_stack:   VectorTextureID,
	_callbacks_data_buf: VectorU8,
	_fringe_scale:       f32,
	_owner_name:         cstring,
}

DrawData :: struct {
	valid:             bool,
	cmd_lists_count:   i32,
	total_idx_count:   i32,
	total_vtx_count:   i32,
	cmd_lists:         VectorDrawListPtr,
	display_pos:       Vec2,
	display_size:      Vec2,
	framebuffer_scale: Vec2,
	owner_viewport:    ^Viewport,
}

FontConfig :: struct {
	font_data:                rawptr,
	font_data_size:           i32,
	font_data_owned_by_atlas: bool,
	font_no:                  i32,
	size_pixels:              f32,
	oversample_h:             i32,
	oversample_v:             i32,
	pixel_snap_h:             bool,
	glyph_extra_spacing:      Vec2,
	glyph_offset:             Vec2,
	glyph_ranges:             cstring,
	glyph_min_advance_x:      f32,
	glyph_max_advance_x:      f32,
	merge_mode:               bool,
	font_builder_flags:       u32,
	rasterizer_multiply:      f32,
	rasterizer_density:       f32,
	ellipsis_char:            Wchar,
	name:                     [40]u8,
	dst_font:                 ^Font,
}

FontGlyph :: struct {
	colored:   u32,
	visible:   u32,
	codepoint: u32,
	advance_x: f32,
	x0:        f32,
	y0:        f32,
	x1:        f32,
	y1:        f32,
	u0:        f32,
	v0:        f32,
	u1:        f32,
	v1:        f32,
}

FontGlyphRangesBuilder :: struct {
	used_chars: VectorU32,
}

FontAtlasCustomRect :: struct {
	x:               u16,
	y:               u16,
	width:           u16,
	height:          u16,
	glyph_id:        u32,
	glyph_colored:   u32,
	glyph_advance_x: f32,
	glyph_offset:    Vec2,
	font:            ^Font,
}

FontAtlas :: struct {
	flags:                 FontAtlasFlags,
	tex_id:                TextureID,
	tex_desired_width:     i32,
	tex_glyph_padding:     i32,
	locked:                bool,
	user_data:             rawptr,
	tex_ready:             bool,
	tex_pixels_use_colors: bool,
	tex_pixels_alpha8:     ^u8,
	tex_pixels_rgba32:     ^u32,
	tex_width:             i32,
	tex_height:            i32,
	tex_uv_scale:          Vec2,
	tex_uv_white_pixel:    Vec2,
	fonts:                 VectorFontPtr,
	custom_rects:          VectorFontAtlasCustomRect,
	config_data:           VectorFontConfig,
	tex_uv_lines:          [DRAWLIST_TEX_LINES_WIDTH_MAX + 1]Vec4,
	font_builder_io:       ^FontBuilderIO,
	font_builder_flags:    u32,
	pack_id_mouse_cursors: i32,
	pack_id_lines:         i32,
}

Font :: struct {
	index_advance_x:       VectorFloat,
	fallback_advance_x:    f32,
	font_size:             f32,
	index_lookup:          VectorWchar,
	glyphs:                VectorFontGlyph,
	fallback_glyph:        ^FontGlyph,
	container_atlas:       ^FontAtlas,
	config_data:           ^FontConfig,
	config_data_count:     i16,
	ellipsis_char_count:   i16,
	ellipsis_char:         Wchar,
	fallback_char:         Wchar,
	ellipsis_width:        f32,
	ellipsis_char_step:    f32,
	dirty_lookup_tables:   bool,
	scale:                 f32,
	ascent:                f32,
	descent:               f32,
	metrics_total_surface: i32,
	used4k_pages_map:      [(UNICODE_CODEPOINT_MAX + 1) / 4096 / 8]u8,
}

Viewport :: struct {
	id:                  ID,
	flags:               ViewportFlags,
	pos:                 Vec2,
	size:                Vec2,
	work_pos:            Vec2,
	work_size:           Vec2,
	platform_handle:     rawptr,
	platform_handle_raw: rawptr,
}

PlatformIO :: struct {
	platform_get_clipboard_text_fn:   proc(ctx: ^Context) -> cstring,
	platform_set_clipboard_text_fn:   proc(ctx: ^Context, text: cstring),
	platform_clipboard_user_data:     rawptr,
	platform_open_in_shell_fn:        proc(ctx: ^Context, path: cstring) -> bool,
	platform_open_in_shell_user_data: rawptr,
	platform_set_ime_data_fn:         proc(
		ctx: ^Context,
		viewport: ^Viewport,
		data: ^PlatformeData,
	),
	platform_ime_user_data:           rawptr,
	platform_locale_decimal_point:    Wchar,
	renderer_render_state:            rawptr,
}

PlatformeData :: struct {
	want_visible:      bool,
	input_pos:         Vec2,
	input_line_height: f32,
}

foreign lib {
	// Context creation and access
	// - Each context create its own ImFontAtlas by default. You may instance one yourself and pass it to CreateContext() to share a font atlas between contexts.
	// - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
	//   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for details.
	@(link_name = "ImGui_CreateContext")
	create_context :: proc(shared_font_atlas: ^FontAtlas = nil) -> ^Context ---
	// NULL = destroy current context
	@(link_name = "ImGui_DestroyContext")
	destroy_context :: proc(ctx: ^Context = nil) ---
	@(link_name = "ImGui_GetCurrentContext")
	get_current_context :: proc() -> ^Context ---
	@(link_name = "ImGui_SetCurrentContext")
	set_current_context :: proc(ctx: ^Context) ---
	// Main
	// access the ImGuiIO structure (mouse/keyboard/gamepad inputs, time, various configuration options/flags)
	@(link_name = "ImGui_GetIO")
	get_io :: proc() -> ^IO ---
	// access the ImGuiPlatformIO structure (mostly hooks/functions to connect to platform/renderer and OS Clipboard, IME etc.)
	@(link_name = "ImGui_GetPlatformIO")
	get_platform_io :: proc() -> ^PlatformIO ---
	// access the Style structure (colors, sizes). Always use PushStyleColor(), PushStyleVar() to modify style mid-frame!
	@(link_name = "ImGui_GetStyle")
	get_style :: proc() -> ^Style ---
	// start a new Dear ImGui frame, you can submit any command from this point until Render()/EndFrame().
	@(link_name = "ImGui_NewFrame")
	new_frame :: proc() ---
	// ends the Dear ImGui frame. automatically called by Render(). If you don't need to render data (skipping rendering) you may call EndFrame() without Render()... but you'll have wasted CPU already! If you don't need to render, better to not create any windows and not call NewFrame() at all!
	@(link_name = "ImGui_EndFrame")
	end_frame :: proc() ---
	// ends the Dear ImGui frame, finalize the draw data. You can then get call GetDrawData().
	@(link_name = "ImGui_Render")
	render :: proc() ---
	// valid after Render() and until the next call to NewFrame(). this is what you have to render.
	@(link_name = "ImGui_GetDrawData")
	get_draw_data :: proc() -> ^DrawData ---
	// Demo, Debug, Information
	// create Demo window. demonstrate most ImGui features. call this to learn about the library! try to make it always available in your application!
	@(link_name = "ImGui_ShowDemoWindow")
	show_demo_window :: proc(p_open: ^bool = nil) ---
	// create Metrics/Debugger window. display Dear ImGui internals: windows, draw commands, various internal state, etc.
	@(link_name = "ImGui_ShowMetricsWindow")
	show_metrics_window :: proc(p_open: ^bool = nil) ---
	// create Debug Log window. display a simplified log of important dear imgui events.
	@(link_name = "ImGui_ShowDebugLogWindow")
	show_debug_log_window :: proc(p_open: ^bool = nil) ---
	// create Stack Tool window. hover items with mouse to query information about the source of their unique ID.
	@(link_name = "ImGui_ShowIDStackToolWindow")
	show_id_stack_tool_window :: proc(p_open: ^bool = nil) ---
	// create About window. display Dear ImGui version, credits and build/system information.
	@(link_name = "ImGui_ShowAboutWindow")
	show_about_window :: proc(p_open: ^bool = nil) ---
	// add style editor block (not a window). you can pass in a reference ImGuiStyle structure to compare to, revert to and save to (else it uses the default style)
	@(link_name = "ImGui_ShowStyleEditor")
	show_style_editor :: proc(ref: ^Style = nil) ---
	// add style selector block (not a window), essentially a combo listing the default styles.
	@(link_name = "ImGui_ShowStyleSelector")
	show_style_selector :: proc(label: cstring) -> bool ---
	// add font selector block (not a window), essentially a combo listing the loaded fonts.
	@(link_name = "ImGui_ShowFontSelector")
	show_font_selector :: proc(label: cstring) ---
	// add basic help/info block (not a window): how to manipulate ImGui as an end-user (mouse/keyboard controls).
	@(link_name = "ImGui_ShowUserGuide")
	show_user_guide :: proc() ---
	// get the compiled version string e.g. "1.80 WIP" (essentially the value for IMGUI_VERSION from the compiled version of imgui.cpp)
	@(link_name = "ImGui_GetVersion")
	get_version :: proc() -> cstring ---
	// Styles
	// new, recommended style (default)
	@(link_name = "ImGui_StyleColorsDark")
	style_colors_dark :: proc(dst: ^Style = nil) ---
	// best used with borders and a custom, thicker font
	@(link_name = "ImGui_StyleColorsLight")
	style_colors_light :: proc(dst: ^Style = nil) ---
	// classic imgui style
	@(link_name = "ImGui_StyleColorsClassic")
	style_colors_classic :: proc(dst: ^Style = nil) ---
	// Windows
	// - Begin() = push window to the stack and start appending to it. End() = pop window from the stack.
	// - Passing 'bool* p_open != NULL' shows a window-closing widget in the upper-right corner of the window,
	//   which clicking will set the boolean to false when clicked.
	// - You may append multiple times to the same window during the same frame by calling Begin()/End() pairs multiple times.
	//   Some information such as 'flags' or 'p_open' will only be considered by the first call to Begin().
	// - Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
	//   anything to the window. Always call a matching End() for each Begin() call, regardless of its return value!
	//   [Important: due to legacy reason, Begin/End and BeginChild/EndChild are inconsistent with all other functions
	//    such as BeginMenu/EndMenu, BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding
	//    BeginXXX function returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
	// - Note that the bottom of window stack always contains a window called "Debug".
	@(link_name = "ImGui_Begin")
	begin :: proc(name: cstring, p_open: ^bool = nil, flags: WindowFlags = {}) -> bool ---
	@(link_name = "ImGui_End")
	end :: proc() ---
	// Child Windows
	// - Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.
	// - Before 1.90 (November 2023), the "ImGuiChildFlags child_flags = 0" parameter was "bool border = false".
	//   This API is backward compatible with old code, as we guarantee that ImGuiChildFlags_Borders == true.
	//   Consider updating your old code:
	//      BeginChild("Name", size, false)   -> Begin("Name", size, 0); or Begin("Name", size, ImGuiChildFlags_None);
	//      BeginChild("Name", size, true)    -> Begin("Name", size, ImGuiChildFlags_Borders);
	// - Manual sizing (each axis can use a different setting e.g. ImVec2(0.0f, 400.0f)):
	//     == 0.0f: use remaining parent window size for this axis.
	//      > 0.0f: use specified size for this axis.
	//      < 0.0f: right/bottom-align to specified distance from available content boundaries.
	// - Specifying ImGuiChildFlags_AutoResizeX or ImGuiChildFlags_AutoResizeY makes the sizing automatic based on child contents.
	//   Combining both ImGuiChildFlags_AutoResizeX _and_ ImGuiChildFlags_AutoResizeY defeats purpose of a scrolling region and is NOT recommended.
	// - BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting
	//   anything to the window. Always call a matching EndChild() for each BeginChild() call, regardless of its return value.
	//   [Important: due to legacy reason, Begin/End and BeginChild/EndChild are inconsistent with all other functions
	//    such as BeginMenu/EndMenu, BeginPopup/EndPopup, etc. where the EndXXX call should only be called if the corresponding
	//    BeginXXX function returned true. Begin and BeginChild are the only odd ones out. Will be fixed in a future update.]
	@(link_name = "ImGui_BeginChild")
	begin_child :: proc(str_id: cstring, size: Vec2 = Vec2{0, 0}, child_flags: ChildFlags = {}, window_flags: WindowFlags = {}) -> bool ---
	@(link_name = "ImGui_BeginChildID")
	begin_child_id :: proc(id: ID, size: Vec2 = Vec2{0, 0}, child_flags: ChildFlags = {}, window_flags: WindowFlags = {}) -> bool ---
	@(link_name = "ImGui_EndChild")
	end_child :: proc() ---
	// Windows Utilities
	// - 'current window' = the window we are appending into while inside a Begin()/End() block. 'next window' = next window we will Begin() into.
	@(link_name = "ImGui_IsWindowAppearing")
	is_window_appearing :: proc() -> bool ---
	@(link_name = "ImGui_IsWindowCollapsed")
	is_window_collapsed :: proc() -> bool ---
	// is current window focused? or its root/child, depending on flags. see flags for options.
	@(link_name = "ImGui_IsWindowFocused")
	is_window_focused :: proc(flags: FocusedFlags = {}) -> bool ---
	// is current window hovered and hoverable (e.g. not blocked by a popup/modal)? See ImGuiHoveredFlags_ for options. IMPORTANT: If you are trying to check whether your mouse should be dispatched to Dear ImGui or to your underlying app, you should not use this function! Use the 'io.WantCaptureMouse' boolean for that! Refer to FAQ entry "How can I tell whether to dispatch mouse/keyboard to Dear ImGui or my application?" for details.
	@(link_name = "ImGui_IsWindowHovered")
	is_window_hovered :: proc(flags: HoveredFlags = {}) -> bool ---
	// get draw list associated to the current window, to append your own drawing primitives
	@(link_name = "ImGui_GetWindowDrawList")
	get_window_draw_list :: proc() -> ^DrawList ---
	// get current window position in screen space (IT IS UNLIKELY YOU EVER NEED TO USE THIS. Consider always using GetCursorScreenPos() and GetContentRegionAvail() instead)
	@(link_name = "ImGui_GetWindowPos")
	get_window_pos :: proc() -> Vec2 ---
	// get current window size (IT IS UNLIKELY YOU EVER NEED TO USE THIS. Consider always using GetCursorScreenPos() and GetContentRegionAvail() instead)
	@(link_name = "ImGui_GetWindowSize")
	get_window_size :: proc() -> Vec2 ---
	// get current window width (IT IS UNLIKELY YOU EVER NEED TO USE THIS). Shortcut for GetWindowSize().x.
	@(link_name = "ImGui_GetWindowWidth")
	get_window_width :: proc() -> f32 ---
	// get current window height (IT IS UNLIKELY YOU EVER NEED TO USE THIS). Shortcut for GetWindowSize().y.
	@(link_name = "ImGui_GetWindowHeight")
	get_window_height :: proc() -> f32 ---
	// Window manipulation
	// - Prefer using SetNextXXX functions (before Begin) rather that SetXXX functions (after Begin).
	// set next window position. call before Begin(). use pivot=(0.5f,0.5f) to center on given point, etc.
	@(link_name = "ImGui_SetNextWindowPos")
	set_next_window_pos :: proc(pos: Vec2, cond: Cond = {}, pivot: Vec2 = Vec2{0, 0}) ---
	// set next window size. set axis to 0.0f to force an auto-fit on this axis. call before Begin()
	@(link_name = "ImGui_SetNextWindowSize")
	set_next_window_size :: proc(size: Vec2, cond: Cond = {}) ---
	// set next window size limits. use 0.0f or FLT_MAX if you don't want limits. Use -1 for both min and max of same axis to preserve current size (which itself is a constraint). Use callback to apply non-trivial programmatic constraints.
	@(link_name = "ImGui_SetNextWindowSizeConstraints")
	set_next_window_size_constraints :: proc(size_min: Vec2, size_max: Vec2, custom_callback: SizeCallback = nil, custom_callback_data: rawptr = nil) ---
	// set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. set an axis to 0.0f to leave it automatic. call before Begin()
	@(link_name = "ImGui_SetNextWindowContentSize")
	set_next_window_content_size :: proc(size: Vec2) ---
	// set next window collapsed state. call before Begin()
	@(link_name = "ImGui_SetNextWindowCollapsed")
	set_next_window_collapsed :: proc(collapsed: bool, cond: Cond = {}) ---
	// set next window to be focused / top-most. call before Begin()
	@(link_name = "ImGui_SetNextWindowFocus")
	set_next_window_focus :: proc() ---
	// set next window scrolling value (use < 0.0f to not affect a given axis).
	@(link_name = "ImGui_SetNextWindowScroll")
	set_next_window_scroll :: proc(scroll: Vec2) ---
	// set next window background color alpha. helper to easily override the Alpha component of ImGuiCol_WindowBg/ChildBg/PopupBg. you may also use ImGuiWindowFlags_NoBackground.
	@(link_name = "ImGui_SetNextWindowBgAlpha")
	set_next_window_bg_alpha :: proc(alpha: f32) ---
	// (not recommended) set current window position - call within Begin()/End(). prefer using SetNextWindowPos(), as this may incur tearing and side-effects.
	@(link_name = "ImGui_SetWindowPos")
	set_window_pos :: proc(pos: Vec2, cond: Cond = {}) ---
	// (not recommended) set current window size - call within Begin()/End(). set to ImVec2(0, 0) to force an auto-fit. prefer using SetNextWindowSize(), as this may incur tearing and minor side-effects.
	@(link_name = "ImGui_SetWindowSize")
	set_window_size :: proc(size: Vec2, cond: Cond = {}) ---
	// (not recommended) set current window collapsed state. prefer using SetNextWindowCollapsed().
	@(link_name = "ImGui_SetWindowCollapsed")
	set_window_collapsed :: proc(collapsed: bool, cond: Cond = {}) ---
	// (not recommended) set current window to be focused / top-most. prefer using SetNextWindowFocus().
	@(link_name = "ImGui_SetWindowFocus")
	set_window_focus :: proc() ---
	// [OBSOLETE] set font scale. Adjust IO.FontGlobalScale if you want to scale all windows. This is an old API! For correct scaling, prefer to reload font + rebuild ImFontAtlas + call style.ScaleAllSizes().
	@(link_name = "ImGui_SetWindowFontScale")
	set_window_font_scale :: proc(scale: f32) ---
	// set named window position.
	@(link_name = "ImGui_SetWindowPosStr")
	set_window_pos_str :: proc(name: cstring, pos: Vec2, cond: Cond = {}) ---
	// set named window size. set axis to 0.0f to force an auto-fit on this axis.
	@(link_name = "ImGui_SetWindowSizeStr")
	set_window_size_str :: proc(name: cstring, size: Vec2, cond: Cond = {}) ---
	// set named window collapsed state
	@(link_name = "ImGui_SetWindowCollapsedStr")
	set_window_collapsed_str :: proc(name: cstring, collapsed: bool, cond: Cond = {}) ---
	// set named window to be focused / top-most. use NULL to remove focus.
	@(link_name = "ImGui_SetWindowFocusStr")
	set_window_focus_str :: proc(name: cstring) ---
	// Windows Scrolling
	// - Any change of Scroll will be applied at the beginning of next frame in the first call to Begin().
	// - You may instead use SetNextWindowScroll() prior to calling Begin() to avoid this delay, as an alternative to using SetScrollX()/SetScrollY().
	// get scrolling amount [0 .. GetScrollMaxX()]
	@(link_name = "ImGui_GetScrollX")
	get_scroll_x :: proc() -> f32 ---
	// get scrolling amount [0 .. GetScrollMaxY()]
	@(link_name = "ImGui_GetScrollY")
	get_scroll_y :: proc() -> f32 ---
	// set scrolling amount [0 .. GetScrollMaxX()]
	@(link_name = "ImGui_SetScrollX")
	set_scroll_x :: proc(scroll_x: f32) ---
	// set scrolling amount [0 .. GetScrollMaxY()]
	@(link_name = "ImGui_SetScrollY")
	set_scroll_y :: proc(scroll_y: f32) ---
	// get maximum scrolling amount ~~ ContentSize.x - WindowSize.x - DecorationsSize.x
	@(link_name = "ImGui_GetScrollMaxX")
	get_scroll_max_x :: proc() -> f32 ---
	// get maximum scrolling amount ~~ ContentSize.y - WindowSize.y - DecorationsSize.y
	@(link_name = "ImGui_GetScrollMaxY")
	get_scroll_max_y :: proc() -> f32 ---
	// adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
	@(link_name = "ImGui_SetScrollHereX")
	set_scroll_here_x :: proc(center_x_ratio: f32 = 0.5) ---
	// adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using SetItemDefaultFocus() instead.
	@(link_name = "ImGui_SetScrollHereY")
	set_scroll_here_y :: proc(center_y_ratio: f32 = 0.5) ---
	// adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
	@(link_name = "ImGui_SetScrollFromPosX")
	set_scroll_from_pos_x :: proc(local_x: f32, center_x_ratio: f32 = 0.5) ---
	// adjust scrolling amount to make given position visible. Generally GetCursorStartPos() + offset to compute a valid position.
	@(link_name = "ImGui_SetScrollFromPosY")
	set_scroll_from_pos_y :: proc(local_y: f32, center_y_ratio: f32 = 0.5) ---
	// Parameters stacks (shared)
	// use NULL as a shortcut to push default font
	@(link_name = "ImGui_PushFont")
	push_font :: proc(font: ^Font) ---
	@(link_name = "ImGui_PopFont")
	pop_font :: proc() ---
	// modify a style color. always use this if you modify the style after NewFrame().
	@(link_name = "ImGui_PushStyleColor")
	push_style_color :: proc(idx: Col, col: u32) ---
	@(link_name = "ImGui_PushStyleColorImVec4")
	push_style_color_vec4 :: proc(idx: Col, col: Vec4) ---
	@(link_name = "ImGui_PopStyleColor")
	pop_style_color :: proc(count: i32 = 1) ---
	// modify a style float variable. always use this if you modify the style after NewFrame()!
	@(link_name = "ImGui_PushStyleVar")
	push_style_var :: proc(idx: StyleVar, val: f32) ---
	// modify a style ImVec2 variable. "
	@(link_name = "ImGui_PushStyleVarImVec2")
	push_style_var_vec2 :: proc(idx: StyleVar, val: Vec2) ---
	// modify X component of a style ImVec2 variable. "
	@(link_name = "ImGui_PushStyleVarX")
	push_style_var_x :: proc(idx: StyleVar, val_x: f32) ---
	// modify Y component of a style ImVec2 variable. "
	@(link_name = "ImGui_PushStyleVarY")
	push_style_var_y :: proc(idx: StyleVar, val_y: f32) ---
	@(link_name = "ImGui_PopStyleVar")
	pop_style_var :: proc(count: i32 = 1) ---
	// modify specified shared item flag, e.g. PushItemFlag(ImGuiItemFlags_NoTabStop, true)
	@(link_name = "ImGui_PushItemFlag")
	push_item_flag :: proc(option: ItemFlags, enabled: bool) ---
	@(link_name = "ImGui_PopItemFlag")
	pop_item_flag :: proc() ---
	// Parameters stacks (current window)
	// push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side).
	@(link_name = "ImGui_PushItemWidth")
	push_item_width :: proc(item_width: f32) ---
	@(link_name = "ImGui_PopItemWidth")
	pop_item_width :: proc() ---
	// set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side)
	@(link_name = "ImGui_SetNextItemWidth")
	set_next_item_width :: proc(item_width: f32) ---
	// width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
	@(link_name = "ImGui_CalcItemWidth")
	calc_item_width :: proc() -> f32 ---
	// push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space
	@(link_name = "ImGui_PushTextWrapPos")
	push_text_wrap_pos :: proc(wrap_local_pos_x: f32 = 0.0) ---
	@(link_name = "ImGui_PopTextWrapPos")
	pop_text_wrap_pos :: proc() ---
	// Style read access
	// - Use the ShowStyleEditor() function to interactively see/edit the colors.
	// get current font
	@(link_name = "ImGui_GetFont")
	get_font :: proc() -> ^Font ---
	// get current font size (= height in pixels) of current font with current scale applied
	@(link_name = "ImGui_GetFontSize")
	get_font_size :: proc() -> f32 ---
	// get UV coordinate for a white pixel, useful to draw custom shapes via the ImDrawList API
	@(link_name = "ImGui_GetFontTexUvWhitePixel")
	get_font_tex_uv_white_pixel :: proc() -> Vec2 ---
	// retrieve given style color with style alpha applied and optional extra alpha multiplier, packed as a 32-bit value suitable for ImDrawList
	@(link_name = "ImGui_GetColorU32")
	get_color_u32 :: proc(idx: Col, alpha_mul: f32 = 1.0) -> u32 ---
	// retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
	@(link_name = "ImGui_GetColorU32ImVec4")
	get_color_u32vec4 :: proc(col: Vec4) -> u32 ---
	// retrieve given color with style alpha applied, packed as a 32-bit value suitable for ImDrawList
	@(link_name = "ImGui_GetColorU32ImU32")
	get_color_u32u32 :: proc(col: u32, alpha_mul: f32 = 1.0) -> u32 ---
	// retrieve style color as stored in ImGuiStyle structure. use to feed back into PushStyleColor(), otherwise use GetColorU32() to get style color with style alpha baked in.
	@(link_name = "ImGui_GetStyleColorVec4")
	get_style_color_vec4 :: proc(idx: Col) -> ^Vec4 ---
	// Layout cursor positioning
	// - By "cursor" we mean the current output position.
	// - The typical widget behavior is to output themselves at the current cursor position, then move the cursor one line down.
	// - You can call SameLine() between widgets to undo the last carriage return and output at the right of the preceding widget.
	// - YOU CAN DO 99% OF WHAT YOU NEED WITH ONLY GetCursorScreenPos() and GetContentRegionAvail().
	// - Attention! We currently have inconsistencies between window-local and absolute positions we will aim to fix with future API:
	//    - Absolute coordinate:        GetCursorScreenPos(), SetCursorScreenPos(), all ImDrawList:: functions. -> this is the preferred way forward.
	//    - Window-local coordinates:   SameLine(offset), GetCursorPos(), SetCursorPos(), GetCursorStartPos(), PushTextWrapPos()
	//    - Window-local coordinates:   GetContentRegionMax(), GetWindowContentRegionMin(), GetWindowContentRegionMax() --> all obsoleted. YOU DON'T NEED THEM.
	// - GetCursorScreenPos() = GetCursorPos() + GetWindowPos(). GetWindowPos() is almost only ever useful to convert from window-local to absolute coordinates. Try not to use it.
	// cursor position, absolute coordinates. THIS IS YOUR BEST FRIEND (prefer using this rather than GetCursorPos(), also more useful to work with ImDrawList API).
	@(link_name = "ImGui_GetCursorScreenPos")
	get_cursor_screen_pos :: proc() -> Vec2 ---
	// cursor position, absolute coordinates. THIS IS YOUR BEST FRIEND.
	@(link_name = "ImGui_SetCursorScreenPos")
	set_cursor_screen_pos :: proc(pos: Vec2) ---
	// available space from current position. THIS IS YOUR BEST FRIEND.
	@(link_name = "ImGui_GetContentRegionAvail")
	get_content_region_avail :: proc() -> Vec2 ---
	// [window-local] cursor position in window-local coordinates. This is not your best friend.
	@(link_name = "ImGui_GetCursorPos")
	get_cursor_pos :: proc() -> Vec2 ---
	// [window-local] "
	@(link_name = "ImGui_GetCursorPosX")
	get_cursor_pos_x :: proc() -> f32 ---
	// [window-local] "
	@(link_name = "ImGui_GetCursorPosY")
	get_cursor_pos_y :: proc() -> f32 ---
	// [window-local] "
	@(link_name = "ImGui_SetCursorPos")
	set_cursor_pos :: proc(local_pos: Vec2) ---
	// [window-local] "
	@(link_name = "ImGui_SetCursorPosX")
	set_cursor_pos_x :: proc(local_x: f32) ---
	// [window-local] "
	@(link_name = "ImGui_SetCursorPosY")
	set_cursor_pos_y :: proc(local_y: f32) ---
	// [window-local] initial cursor position, in window-local coordinates. Call GetCursorScreenPos() after Begin() to get the absolute coordinates version.
	@(link_name = "ImGui_GetCursorStartPos")
	get_cursor_start_pos :: proc() -> Vec2 ---
	// Other layout functions
	// separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
	@(link_name = "ImGui_Separator")
	separator :: proc() ---
	// call between widgets or groups to layout them horizontally. X position given in window coordinates.
	@(link_name = "ImGui_SameLine")
	same_line :: proc(offset_from_start_x: f32 = 0.0, spacing: f32 = -1.0) ---
	// undo a SameLine() or force a new line when in a horizontal-layout context.
	@(link_name = "ImGui_NewLine")
	new_line :: proc() ---
	// add vertical spacing.
	@(link_name = "ImGui_Spacing")
	spacing :: proc() ---
	// add a dummy item of given size. unlike InvisibleButton(), Dummy() won't take the mouse click or be navigable into.
	@(link_name = "ImGui_Dummy")
	dummy :: proc(size: Vec2) ---
	// move content position toward the right, by indent_w, or style.IndentSpacing if indent_w <= 0
	@(link_name = "ImGui_Indent")
	indent :: proc(indent_w: f32 = 0.0) ---
	// move content position back to the left, by indent_w, or style.IndentSpacing if indent_w <= 0
	@(link_name = "ImGui_Unindent")
	unindent :: proc(indent_w: f32 = 0.0) ---
	// lock horizontal starting position
	@(link_name = "ImGui_BeginGroup")
	begin_group :: proc() ---
	// unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
	@(link_name = "ImGui_EndGroup")
	end_group :: proc() ---
	// vertically align upcoming text baseline to FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
	@(link_name = "ImGui_AlignTextToFramePadding")
	align_text_to_frame_padding :: proc() ---
	// ~ FontSize
	@(link_name = "ImGui_GetTextLineHeight")
	get_text_line_height :: proc() -> f32 ---
	// ~ FontSize + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
	@(link_name = "ImGui_GetTextLineHeightWithSpacing")
	get_text_line_height_with_spacing :: proc() -> f32 ---
	// ~ FontSize + style.FramePadding.y * 2
	@(link_name = "ImGui_GetFrameHeight")
	get_frame_height :: proc() -> f32 ---
	// ~ FontSize + style.FramePadding.y * 2 + style.ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)
	@(link_name = "ImGui_GetFrameHeightWithSpacing")
	get_frame_height_with_spacing :: proc() -> f32 ---
	// ID stack/scopes
	// Read the FAQ (docs/FAQ.md or http://dearimgui.com/faq) for more details about how ID are handled in dear imgui.
	// - Those questions are answered and impacted by understanding of the ID stack system:
	//   - "Q: Why is my widget not reacting when I click on it?"
	//   - "Q: How can I have widgets with an empty label?"
	//   - "Q: How can I have multiple widgets with the same label?"
	// - Short version: ID are hashes of the entire ID stack. If you are creating widgets in a loop you most likely
	//   want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.
	// - You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
	// - In this header file we use the "label"/"name" terminology to denote a string that will be displayed + used as an ID,
	//   whereas "str_id" denote a string that is only used as an ID and not normally displayed.
	// push string into the ID stack (will hash string).
	@(link_name = "ImGui_PushID")
	push_id :: proc(str_id: cstring) ---
	// push string into the ID stack (will hash string).
	@(link_name = "ImGui_PushIDStr")
	push_id_str :: proc(str_id_begin: cstring, str_id_end: cstring) ---
	// push pointer into the ID stack (will hash pointer).
	@(link_name = "ImGui_PushIDPtr")
	push_id_ptr :: proc(ptr_id: rawptr) ---
	// push integer into the ID stack (will hash integer).
	@(link_name = "ImGui_PushIDInt")
	push_id_int :: proc(int_id: i32) ---
	// pop from the ID stack.
	@(link_name = "ImGui_PopID")
	pop_id :: proc() ---
	// calculate unique ID (hash of whole ID stack + given parameter). e.g. if you want to query into ImGuiStorage yourself
	@(link_name = "ImGui_GetID")
	get_id :: proc(str_id: cstring) -> ID ---
	@(link_name = "ImGui_GetIDStr")
	get_id_str :: proc(str_id_begin: cstring, str_id_end: cstring) -> ID ---
	@(link_name = "ImGui_GetIDPtr")
	get_id_ptr :: proc(ptr_id: rawptr) -> ID ---
	@(link_name = "ImGui_GetIDInt")
	get_id_int :: proc(int_id: i32) -> ID ---
	// Widgets: Text
	// raw text without formatting. Roughly equivalent to Text("%s", text) but: A) doesn't require null terminated string if 'text_end' is specified, B) it's faster, no memory copy is done, no buffer size limits, recommended for long chunks of text.
	@(link_name = "ImGui_TextUnformatted")
	text_unformatted :: proc(text: cstring, text_end: cstring = nil) ---
	// formatted text
	@(link_name = "ImGui_Text")
	text :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// shortcut for PushStyleColor(ImGuiCol_Text, col); Text(fmt, ...); PopStyleColor();
	@(link_name = "ImGui_TextColored")
	text_colored :: proc(col: Vec4, fmt: cstring, #c_vararg args: ..any) ---
	// shortcut for PushStyleColor(ImGuiCol_Text, style.Colors[ImGuiCol_TextDisabled]); Text(fmt, ...); PopStyleColor();
	@(link_name = "ImGui_TextDisabled")
	text_disabled :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// shortcut for PushTextWrapPos(0.0f); Text(fmt, ...); PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using SetNextWindowSize().
	@(link_name = "ImGui_TextWrapped")
	text_wrapped :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// display text+label aligned the same way as value+label widgets
	@(link_name = "ImGui_LabelText")
	label_text :: proc(label: cstring, fmt: cstring, #c_vararg args: ..any) ---
	// shortcut for Bullet()+Text()
	@(link_name = "ImGui_BulletText")
	bullet_text :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// currently: formatted text with an horizontal line
	@(link_name = "ImGui_SeparatorText")
	separator_text :: proc(label: cstring) ---
	// Widgets: Main
	// - Most widgets return true when the value has been changed or when pressed/selected
	// - You may also use one of the many IsItemXXX functions (e.g. IsItemActive, IsItemHovered, etc.) to query widget state.
	// button
	@(link_name = "ImGui_Button")
	button :: proc(label: cstring, size: Vec2 = Vec2{0, 0}) -> bool ---
	// button with (FramePadding.y == 0) to easily embed within text
	@(link_name = "ImGui_SmallButton")
	small_button :: proc(label: cstring) -> bool ---
	// flexible button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with IsItemActive, IsItemHovered, etc.)
	@(link_name = "ImGui_InvisibleButton")
	invisible_button :: proc(str_id: cstring, size: Vec2, flags: ButtonFlags = {}) -> bool ---
	// square button with an arrow shape
	@(link_name = "ImGui_ArrowButton")
	arrow_button :: proc(str_id: cstring, dir: Dir) -> bool ---
	@(link_name = "ImGui_Checkbox")
	checkbox :: proc(label: cstring, v: ^bool) -> bool ---
	@(link_name = "ImGui_CheckboxFlagsIntPtr")
	checkbox_flags_int_ptr :: proc(label: cstring, flags: ^i32, flags_value: i32) -> bool ---
	@(link_name = "ImGui_CheckboxFlagsUintPtr")
	checkbox_flags_uint_ptr :: proc(label: cstring, flags: ^u32, flags_value: u32) -> bool ---
	// use with e.g. if (RadioButton("one", my_value==1)) { my_value = 1; }
	@(link_name = "ImGui_RadioButton")
	radio_button :: proc(label: cstring, active: bool) -> bool ---
	// shortcut to handle the above pattern when value is an integer
	@(link_name = "ImGui_RadioButtonIntPtr")
	radio_button_int_ptr :: proc(label: cstring, v: ^i32, v_button: i32) -> bool ---
	@(link_name = "ImGui_ProgressBar")
	progress_bar :: proc(fraction: f32, size_arg: Vec2 = Vec2{-min(f32), 0}, overlay: cstring = nil) ---
	// draw a small circle + keep the cursor on the same line. advance cursor x position by GetTreeNodeToLabelSpacing(), same distance that TreeNode() uses
	@(link_name = "ImGui_Bullet")
	bullet :: proc() ---
	// hyperlink text button, return true when clicked
	@(link_name = "ImGui_TextLink")
	text_link :: proc(label: cstring) -> bool ---
	// hyperlink text button, automatically open file/url when clicked
	@(link_name = "ImGui_TextLinkOpenURL")
	text_link_open_url :: proc(label: cstring, url: cstring = nil) ---
	// Widgets: Images
	// - Read about ImTextureID here: https://github.com/ocornut/imgui/wiki/Image-Loading-and-Displaying-Examples
	// - 'uv0' and 'uv1' are texture coordinates. Read about them from the same link above.
	// - Note that Image() may add +2.0f to provided size if a border is visible, ImageButton() adds style.FramePadding*2.0f to provided size.
	// - ImageButton() draws a background based on regular Button() color + optionally an inner background if specified.
	@(link_name = "ImGui_Image")
	image :: proc(user_texture_id: TextureID, image_size: Vec2, uv0: Vec2 = Vec2{0, 0}, uv1: Vec2 = Vec2{1, 1}, tint_col: Vec4 = Vec4{1, 1, 1, 1}, border_col: Vec4 = Vec4{0, 0, 0, 0}) ---
	@(link_name = "ImGui_ImageButton")
	image_button :: proc(str_id: cstring, user_texture_id: TextureID, image_size: Vec2, uv0: Vec2 = Vec2{0, 0}, uv1: Vec2 = Vec2{1, 1}, bg_col: Vec4 = Vec4{0, 0, 0, 0}, tint_col: Vec4 = Vec4{1, 1, 1, 1}) -> bool ---
	// Widgets: Combo Box (Dropdown)
	// - The BeginCombo()/EndCombo() api allows you to manage your contents and selection state however you want it, by creating e.g. Selectable() items.
	// - The old Combo() api are helpers over BeginCombo()/EndCombo() which are kept available for convenience purpose. This is analogous to how ListBox are created.
	@(link_name = "ImGui_BeginCombo")
	begin_combo :: proc(label: cstring, preview_value: cstring, flags: ComboFlags = {}) -> bool ---
	// only call EndCombo() if BeginCombo() returns true!
	@(link_name = "ImGui_EndCombo")
	end_combo :: proc() ---
	@(link_name = "ImGui_ComboChar")
	combo_char :: proc(label: cstring, current_item: ^i32, items: [^]cstring, items_count: i32, popup_max_height_in_items: i32 = -1) -> bool ---
	// Separate items with \0 within a string, end item-list with \0\0. e.g. "One\0Two\0Three\0"
	@(link_name = "ImGui_Combo")
	combo :: proc(label: cstring, current_item: ^i32, items_separated_by_zeros: cstring, popup_max_height_in_items: i32 = -1) -> bool ---
	@(link_name = "ImGui_ComboCallback")
	combo_callback :: proc(label: cstring, current_item: ^i32, getter: proc(user_data: rawptr, idx: i32) -> cstring, user_data: rawptr, items_count: i32, popup_max_height_in_items: i32 = -1) -> bool ---
	// Widgets: Drag Sliders
	// - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
	// - For all the Float2/Float3/Float4/Int2/Int3/Int4 versions of every function, note that a 'float v[X]' function argument is the same as 'float* v',
	//   the array syntax is just a way to document the number of elements that are expected to be accessible. You can pass address of your first element out of a contiguous set, e.g. &myvector.x
	// - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
	// - Format string may also be set to NULL or use the default format ("%f" or "%d").
	// - Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For keyboard/gamepad navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).
	// - Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits if ImGuiSliderFlags_AlwaysClamp is not used.
	// - Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.
	// - We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.
	// - Legacy: Pre-1.78 there are DragXXX() function signatures that take a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
	//   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
	// If v_min >= v_max we have no bound
	@(link_name = "ImGui_DragFloat")
	drag_float :: proc(label: cstring, v: ^f32, v_speed: f32 = 1.0, v_min: f32 = 0.0, v_max: f32 = 0.0, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragFloat2")
	drag_float2 :: proc(label: cstring, v: ^[2]f32, v_speed: f32 = 1.0, v_min: f32 = 0.0, v_max: f32 = 0.0, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragFloat3")
	drag_float3 :: proc(label: cstring, v: ^[3]f32, v_speed: f32 = 1.0, v_min: f32 = 0.0, v_max: f32 = 0.0, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragFloat4")
	drag_float4 :: proc(label: cstring, v: ^[4]f32, v_speed: f32 = 1.0, v_min: f32 = 0.0, v_max: f32 = 0.0, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragFloatRange2")
	drag_float_range2 :: proc(label: cstring, v_current_min: ^f32, v_current_max: ^f32, v_speed: f32 = 1.0, v_min: f32 = 0.0, v_max: f32 = 0.0, format: cstring = "%.3f", format_max: cstring = nil, flags: SliderFlags = {}) -> bool ---
	// If v_min >= v_max we have no bound
	@(link_name = "ImGui_DragInt")
	drag_int :: proc(label: cstring, v: ^i32, v_speed: f32 = 1.0, v_min: i32 = 0, v_max: i32 = 0, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragInt2")
	drag_int2 :: proc(label: cstring, v: ^[2]i32, v_speed: f32 = 1.0, v_min: i32 = 0, v_max: i32 = 0, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragInt3")
	drag_int3 :: proc(label: cstring, v: ^[3]i32, v_speed: f32 = 1.0, v_min: i32 = 0, v_max: i32 = 0, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragInt4")
	drag_int4 :: proc(label: cstring, v: ^[4]i32, v_speed: f32 = 1.0, v_min: i32 = 0, v_max: i32 = 0, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragIntRange2")
	drag_int_range2 :: proc(label: cstring, v_current_min: ^i32, v_current_max: ^i32, v_speed: f32 = 1.0, v_min: i32 = 0, v_max: i32 = 0, format: cstring = "%d", format_max: cstring = nil, flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragScalar")
	drag_scalar :: proc(label: cstring, data_type: DataType, p_data: rawptr, v_speed: f32 = 1.0, p_min: rawptr = nil, p_max: rawptr = nil, format: cstring = nil, flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_DragScalarN")
	drag_scalar_n :: proc(label: cstring, data_type: DataType, p_data: rawptr, components: i32, v_speed: f32 = 1.0, p_min: rawptr = nil, p_max: rawptr = nil, format: cstring = nil, flags: SliderFlags = {}) -> bool ---
	// Widgets: Regular Sliders
	// - CTRL+Click on any slider to turn them into an input box. Manually input values aren't clamped by default and can go off-bounds. Use ImGuiSliderFlags_AlwaysClamp to always clamp.
	// - Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.
	// - Format string may also be set to NULL or use the default format ("%f" or "%d").
	// - Legacy: Pre-1.78 there are SliderXXX() function signatures that take a final `float power=1.0f' argument instead of the `ImGuiSliderFlags flags=0' argument.
	//   If you get a warning converting a float to ImGuiSliderFlags, read https://github.com/ocornut/imgui/issues/3361
	// adjust format to decorate the value with a prefix or a suffix for in-slider labels or unit display.
	@(link_name = "ImGui_SliderFloat")
	slider_float :: proc(label: cstring, v: ^f32, v_min: f32, v_max: f32, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderFloat2")
	slider_float2 :: proc(label: cstring, v: ^[2]f32, v_min: f32, v_max: f32, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderFloat3")
	slider_float3 :: proc(label: cstring, v: ^[3]f32, v_min: f32, v_max: f32, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderFloat4")
	slider_float4 :: proc(label: cstring, v: ^[4]f32, v_min: f32, v_max: f32, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderAngle")
	slider_angle :: proc(label: cstring, v_rad: ^f32, v_degrees_min: f32 = -360.0, v_degrees_max: f32 = +360.0, format: cstring = "%.0f deg", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderInt")
	slider_int :: proc(label: cstring, v: ^i32, v_min: i32, v_max: i32, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderInt2")
	slider_int2 :: proc(label: cstring, v: ^[2]i32, v_min: i32, v_max: i32, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderInt3")
	slider_int3 :: proc(label: cstring, v: ^[3]i32, v_min: i32, v_max: i32, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderInt4")
	slider_int4 :: proc(label: cstring, v: ^[4]i32, v_min: i32, v_max: i32, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderScalar")
	slider_scalar :: proc(label: cstring, data_type: DataType, p_data: rawptr, p_min: rawptr, p_max: rawptr, format: cstring = nil, flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_SliderScalarN")
	slider_scalar_n :: proc(label: cstring, data_type: DataType, p_data: rawptr, components: i32, p_min: rawptr, p_max: rawptr, format: cstring = nil, flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_VSliderFloat")
	v_slider_float :: proc(label: cstring, size: Vec2, v: ^f32, v_min: f32, v_max: f32, format: cstring = "%.3f", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_VSliderInt")
	v_slider_int :: proc(label: cstring, size: Vec2, v: ^i32, v_min: i32, v_max: i32, format: cstring = "%d", flags: SliderFlags = {}) -> bool ---
	@(link_name = "ImGui_VSliderScalar")
	v_slider_scalar :: proc(label: cstring, size: Vec2, data_type: DataType, p_data: rawptr, p_min: rawptr, p_max: rawptr, format: cstring = nil, flags: SliderFlags = {}) -> bool ---
	// Widgets: Input with Keyboard
	// - If you want to use InputText() with std::string or any custom dynamic string type, see misc/cpp/imgui_stdlib.h and comments in imgui_demo.cpp.
	// - Most of the ImGuiInputTextFlags flags are only useful for InputText() and not for InputFloatX, InputIntX, InputDouble etc.
	@(link_name = "ImGui_InputText")
	input_text :: proc(label: cstring, buf: cstring, buf_size: uint, flags: InputTextFlags = {}, callback: InputTextCallback = nil, user_data: rawptr = nil) -> bool ---
	@(link_name = "ImGui_InputTextMultiline")
	input_text_multiline :: proc(label: cstring, buf: cstring, buf_size: uint, size: Vec2 = Vec2{0, 0}, flags: InputTextFlags = {}, callback: InputTextCallback = nil, user_data: rawptr = nil) -> bool ---
	@(link_name = "ImGui_InputTextWithHint")
	input_text_with_hint :: proc(label: cstring, hint: cstring, buf: cstring, buf_size: uint, flags: InputTextFlags = {}, callback: InputTextCallback = nil, user_data: rawptr = nil) -> bool ---
	@(link_name = "ImGui_InputFloat")
	input_float :: proc(label: cstring, v: ^f32, step: f32 = 0.0, step_fast: f32 = 0.0, format: cstring = "%.3f", flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputFloat2")
	input_float2 :: proc(label: cstring, v: ^[2]f32, format: cstring = "%.3f", flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputFloat3")
	input_float3 :: proc(label: cstring, v: ^[3]f32, format: cstring = "%.3f", flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputFloat4")
	input_float4 :: proc(label: cstring, v: ^[4]f32, format: cstring = "%.3f", flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputInt")
	input_int :: proc(label: cstring, v: ^i32, step: i32 = 1, step_fast: i32 = 100, flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputInt2")
	input_int2 :: proc(label: cstring, v: ^[2]i32, flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputInt3")
	input_int3 :: proc(label: cstring, v: ^[3]i32, flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputInt4")
	input_int4 :: proc(label: cstring, v: ^[4]i32, flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputDouble")
	input_double :: proc(label: cstring, v: ^f64, step: f64 = 0.0, step_fast: f64 = 0.0, format: cstring = "%.6f", flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputScalar")
	input_scalar :: proc(label: cstring, data_type: DataType, p_data: rawptr, p_step: rawptr = nil, p_step_fast: rawptr = nil, format: cstring = nil, flags: InputTextFlags = {}) -> bool ---
	@(link_name = "ImGui_InputScalarN")
	input_scalar_n :: proc(label: cstring, data_type: DataType, p_data: rawptr, components: i32, p_step: rawptr = nil, p_step_fast: rawptr = nil, format: cstring = nil, flags: InputTextFlags = {}) -> bool ---
	// Widgets: Color Editor/Picker (tip: the ColorEdit* functions have a little color square that can be left-clicked to open a picker, and right-clicked to open an option menu.)
	// - Note that in C++ a 'float v[X]' function argument is the _same_ as 'float* v', the array syntax is just a way to document the number of elements that are expected to be accessible.
	// - You can pass the address of a first float element out of a contiguous structure, e.g. &myvector.x
	@(link_name = "ImGui_ColorEdit3")
	color_edit3 :: proc(label: cstring, col: ^[3]f32, flags: ColorEditFlags = {}) -> bool ---
	@(link_name = "ImGui_ColorEdit4")
	color_edit4 :: proc(label: cstring, col: ^[4]f32, flags: ColorEditFlags = {}) -> bool ---
	@(link_name = "ImGui_ColorPicker3")
	color_picker3 :: proc(label: cstring, col: ^[3]f32, flags: ColorEditFlags = {}) -> bool ---
	@(link_name = "ImGui_ColorPicker4")
	color_picker4 :: proc(label: cstring, col: ^[4]f32, flags: ColorEditFlags = {}, ref_col: ^f32 = nil) -> bool ---
	// display a color square/button, hover for details, return true when pressed.
	@(link_name = "ImGui_ColorButton")
	color_button :: proc(desc_id: cstring, col: Vec4, flags: ColorEditFlags = {}, size: Vec2 = Vec2{0, 0}) -> bool ---
	// initialize current options (generally on application startup) if you want to select a default format, picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.
	@(link_name = "ImGui_SetColorEditOptions")
	set_color_edit_options :: proc(flags: ColorEditFlags) ---
	// Widgets: Trees
	// - TreeNode functions return true when the node is open, in which case you need to also call TreePop() when you are finished displaying the tree node contents.
	@(link_name = "ImGui_TreeNode")
	tree_node :: proc(label: cstring) -> bool ---
	// helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a TreeNode() you can use Bullet().
	@(link_name = "ImGui_TreeNodeStr")
	tree_node_str :: proc(str_id: cstring, fmt: cstring, #c_vararg args: ..any) -> bool ---
	// "
	@(link_name = "ImGui_TreeNodePtr")
	tree_node_ptr :: proc(ptr_id: rawptr, fmt: cstring, #c_vararg args: ..any) -> bool ---
	@(link_name = "ImGui_TreeNodeEx")
	tree_node_ex :: proc(label: cstring, flags: TreeNodeFlags = {}) -> bool ---
	@(link_name = "ImGui_TreeNodeExStr")
	tree_node_ex_str :: proc(str_id: cstring, flags: TreeNodeFlags, fmt: cstring, #c_vararg args: ..any) -> bool ---
	@(link_name = "ImGui_TreeNodeExPtr")
	tree_node_ex_ptr :: proc(ptr_id: rawptr, flags: TreeNodeFlags, fmt: cstring, #c_vararg args: ..any) -> bool ---
	// ~ Indent()+PushID(). Already called by TreeNode() when returning true, but you can call TreePush/TreePop yourself if desired.
	@(link_name = "ImGui_TreePush")
	tree_push :: proc(str_id: cstring) ---
	// "
	@(link_name = "ImGui_TreePushPtr")
	tree_push_ptr :: proc(ptr_id: rawptr) ---
	// ~ Unindent()+PopID()
	@(link_name = "ImGui_TreePop")
	tree_pop :: proc() ---
	// horizontal distance preceding label when using TreeNode*() or Bullet() == (g.FontSize + style.FramePadding.x*2) for a regular unframed TreeNode
	@(link_name = "ImGui_GetTreeNodeToLabelSpacing")
	get_tree_node_to_label_spacing :: proc() -> f32 ---
	// if returning 'true' the header is open. doesn't indent nor push on ID stack. user doesn't have to call TreePop().
	@(link_name = "ImGui_CollapsingHeader")
	collapsing_header :: proc(label: cstring, flags: TreeNodeFlags = {}) -> bool ---
	// when 'p_visible != NULL': if '*p_visible==true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if '*p_visible==false' don't display the header.
	@(link_name = "ImGui_CollapsingHeaderBoolPtr")
	collapsing_header_bool_ptr :: proc(label: cstring, p_visible: ^bool, flags: TreeNodeFlags = {}) -> bool ---
	// set next TreeNode/CollapsingHeader open state.
	@(link_name = "ImGui_SetNextItemOpen")
	set_next_item_open :: proc(is_open: bool, cond: Cond = {}) ---
	// set id to use for open/close storage (default to same as item id).
	@(link_name = "ImGui_SetNextItemStorageID")
	set_next_item_storage_id :: proc(storage_id: ID) ---
	// Widgets: Selectables
	// - A selectable highlights when hovered, and can display another color when selected.
	// - Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.
	// "bool selected" carry the selection state (read-only). Selectable() is clicked is returns true so you can modify your selection state. size.x==0.0: use remaining width, size.x>0.0: specify width. size.y==0.0: use label height, size.y>0.0: specify height
	@(link_name = "ImGui_Selectable")
	selectable :: proc(label: cstring, selected: bool = false, flags: SelectableFlags = {}, size: Vec2 = Vec2{0, 0}) -> bool ---
	// "bool* p_selected" point to the selection state (read-write), as a convenient helper.
	@(link_name = "ImGui_SelectableBoolPtr")
	selectable_bool_ptr :: proc(label: cstring, p_selected: ^bool, flags: SelectableFlags = {}, size: Vec2 = Vec2{0, 0}) -> bool ---
	// Multi-selection system for Selectable(), Checkbox(), TreeNode() functions [BETA]
	// - This enables standard multi-selection/range-selection idioms (CTRL+Mouse/Keyboard, SHIFT+Mouse/Keyboard, etc.) in a way that also allow a clipper to be used.
	// - ImGuiSelectionUserData is often used to store your item index within the current view (but may store something else).
	// - Read comments near ImGuiMultiSelectIO for instructions/details and see 'Demo->Widgets->Selection State & Multi-Select' for demo.
	// - TreeNode() is technically supported but... using this correctly is more complicated. You need some sort of linear/random access to your tree,
	//   which is suited to advanced trees setups already implementing filters and clipper. We will work simplifying the current demo.
	// - 'selection_size' and 'items_count' parameters are optional and used by a few features. If they are costly for you to compute, you may avoid them.
	@(link_name = "ImGui_BeginMultiSelect")
	begin_multi_select :: proc(flags: MultiSelectFlags, selection_size: i32 = -1, items_count: i32 = -1) -> ^MultiSelectIO ---
	@(link_name = "ImGui_EndMultiSelect")
	end_multi_select :: proc() -> ^MultiSelectIO ---
	@(link_name = "ImGui_SetNextItemSelectionUserData")
	set_next_item_selection_user_data :: proc(selection_user_data: SelectionUserData) ---
	// Was the last item selection state toggled? Useful if you need the per-item information _before_ reaching EndMultiSelect(). We only returns toggle _event_ in order to handle clipping correctly.
	@(link_name = "ImGui_IsItemToggledSelection")
	is_item_toggled_selection :: proc() -> bool ---
	// Widgets: List Boxes
	// - This is essentially a thin wrapper to using BeginChild/EndChild with the ImGuiChildFlags_FrameStyle flag for stylistic changes + displaying a label.
	// - You can submit contents and manage your selection state however you want it, by creating e.g. Selectable() or any other items.
	// - The simplified/old ListBox() api are helpers over BeginListBox()/EndListBox() which are kept available for convenience purpose. This is analoguous to how Combos are created.
	// - Choose frame width:   size.x > 0.0f: custom  /  size.x < 0.0f or -FLT_MIN: right-align   /  size.x = 0.0f (default): use current ItemWidth
	// - Choose frame height:  size.y > 0.0f: custom  /  size.y < 0.0f or -FLT_MIN: bottom-align  /  size.y = 0.0f (default): arbitrary default height which can fit ~7 items
	// open a framed scrolling region
	@(link_name = "ImGui_BeginListBox")
	begin_list_box :: proc(label: cstring, size: Vec2 = Vec2{0, 0}) -> bool ---
	// only call EndListBox() if BeginListBox() returned true!
	@(link_name = "ImGui_EndListBox")
	end_list_box :: proc() ---
	@(link_name = "ImGui_ListBox")
	list_box :: proc(label: cstring, current_item: ^i32, items: [^]cstring, items_count: i32, height_in_items: i32 = -1) -> bool ---
	@(link_name = "ImGui_ListBoxCallback")
	list_box_callback :: proc(label: cstring, current_item: ^i32, getter: proc(user_data: rawptr, idx: i32) -> cstring, user_data: rawptr, items_count: i32, height_in_items: i32 = -1) -> bool ---
	// Widgets: Data Plotting
	// - Consider using ImPlot (https://github.com/epezent/implot) which is much better!
	@(link_name = "ImGui_PlotLines")
	plot_lines :: proc(label: cstring, values: ^f32, values_count: i32, values_offset: i32 = 0, overlay_text: cstring = nil, scale_min: f32 = max(f32), scale_max: f32 = max(f32), graph_size: Vec2 = Vec2{0, 0}, stride: i32 = size_of(f32)) ---
	@(link_name = "ImGui_PlotLinesCallback")
	plot_lines_callback :: proc(label: cstring, values_getter: proc(data: rawptr, idx: i32) -> f32, data: rawptr, values_count: i32, values_offset: i32 = 0, overlay_text: cstring = nil, scale_min: f32 = max(f32), scale_max: f32 = max(f32), graph_size: Vec2 = Vec2{0, 0}) ---
	@(link_name = "ImGui_PlotHistogram")
	plot_histogram :: proc(label: cstring, values: ^f32, values_count: i32, values_offset: i32 = 0, overlay_text: cstring = nil, scale_min: f32 = max(f32), scale_max: f32 = max(f32), graph_size: Vec2 = Vec2{0, 0}, stride: i32 = size_of(f32)) ---
	@(link_name = "ImGui_PlotHistogramCallback")
	plot_histogram_callback :: proc(label: cstring, values_getter: proc(data: rawptr, idx: i32) -> f32, data: rawptr, values_count: i32, values_offset: i32 = 0, overlay_text: cstring = nil, scale_min: f32 = max(f32), scale_max: f32 = max(f32), graph_size: Vec2 = Vec2{0, 0}) ---
	// Widgets: Menus
	// - Use BeginMenuBar() on a window ImGuiWindowFlags_MenuBar to append to its menu bar.
	// - Use BeginMainMenuBar() to create a menu bar at the top of the screen and append to it.
	// - Use BeginMenu() to create a menu. You can call BeginMenu() multiple time with the same identifier to append more items to it.
	// - Not that MenuItem() keyboardshortcuts are displayed as a convenience but _not processed_ by Dear ImGui at the moment.
	// append to menu-bar of current window (requires ImGuiWindowFlags_MenuBar flag set on parent window).
	@(link_name = "ImGui_BeginMenuBar")
	begin_menu_bar :: proc() -> bool ---
	// only call EndMenuBar() if BeginMenuBar() returns true!
	@(link_name = "ImGui_EndMenuBar")
	end_menu_bar :: proc() ---
	// create and append to a full screen menu-bar.
	@(link_name = "ImGui_BeginMainMenuBar")
	begin_main_menu_bar :: proc() -> bool ---
	// only call EndMainMenuBar() if BeginMainMenuBar() returns true!
	@(link_name = "ImGui_EndMainMenuBar")
	end_main_menu_bar :: proc() ---
	// create a sub-menu entry. only call EndMenu() if this returns true!
	@(link_name = "ImGui_BeginMenu")
	begin_menu :: proc(label: cstring, enabled: bool = true) -> bool ---
	// only call EndMenu() if BeginMenu() returns true!
	@(link_name = "ImGui_EndMenu")
	end_menu :: proc() ---
	// return true when activated.
	@(link_name = "ImGui_MenuItem")
	menu_item :: proc(label: cstring, shortcut: cstring = nil, selected: bool = false, enabled: bool = true) -> bool ---
	// return true when activated + toggle (*p_selected) if p_selected != NULL
	@(link_name = "ImGui_MenuItemBoolPtr")
	menu_item_bool_ptr :: proc(label: cstring, shortcut: cstring, p_selected: ^bool, enabled: bool = true) -> bool ---
	// Tooltips
	// - Tooltips are windows following the mouse. They do not take focus away.
	// - A tooltip window can contain items of any types.
	// - SetTooltip() is more or less a shortcut for the 'if (BeginTooltip()) { Text(...); EndTooltip(); }' idiom (with a subtlety that it discard any previously submitted tooltip)
	// begin/append a tooltip window.
	@(link_name = "ImGui_BeginTooltip")
	begin_tooltip :: proc() -> bool ---
	// only call EndTooltip() if BeginTooltip()/BeginItemTooltip() returns true!
	@(link_name = "ImGui_EndTooltip")
	end_tooltip :: proc() ---
	// set a text-only tooltip. Often used after a ImGui::IsItemHovered() check. Override any previous call to SetTooltip().
	@(link_name = "ImGui_SetTooltip")
	set_tooltip :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// Tooltips: helpers for showing a tooltip when hovering an item
	// - BeginItemTooltip() is a shortcut for the 'if (IsItemHovered(ImGuiHoveredFlags_ForTooltip) && BeginTooltip())' idiom.
	// - SetItemTooltip() is a shortcut for the 'if (IsItemHovered(ImGuiHoveredFlags_ForTooltip)) { SetTooltip(...); }' idiom.
	// - Where 'ImGuiHoveredFlags_ForTooltip' itself is a shortcut to use 'style.HoverFlagsForTooltipMouse' or 'style.HoverFlagsForTooltipNav' depending on active input type. For mouse it defaults to 'ImGuiHoveredFlags_Stationary | ImGuiHoveredFlags_DelayShort'.
	// begin/append a tooltip window if preceding item was hovered.
	@(link_name = "ImGui_BeginItemTooltip")
	begin_item_tooltip :: proc() -> bool ---
	// set a text-only tooltip if preceding item was hovered. override any previous call to SetTooltip().
	@(link_name = "ImGui_SetItemTooltip")
	set_item_tooltip :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// Popups, Modals
	//  - They block normal mouse hovering detection (and therefore most mouse interactions) behind them.
	//  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
	//  - Their visibility state (~bool) is held internally instead of being held by the programmer as we are used to with regular Begin*() calls.
	//  - The 3 properties above are related: we need to retain popup visibility state in the library because popups may be closed as any time.
	//  - You can bypass the hovering restriction by using ImGuiHoveredFlags_AllowWhenBlockedByPopup when calling IsItemHovered() or IsWindowHovered().
	//  - IMPORTANT: Popup identifiers are relative to the current ID stack, so OpenPopup and BeginPopup generally needs to be at the same level of the stack.
	//    This is sometimes leading to confusing mistakes. May rework this in the future.
	//  - BeginPopup(): query popup state, if open start appending into the window. Call EndPopup() afterwards if returned true. ImGuiWindowFlags are forwarded to the window.
	//  - BeginPopupModal(): block every interaction behind the window, cannot be closed by user, add a dimming background, has a title bar.
	// return true if the popup is open, and you can start outputting to it.
	@(link_name = "ImGui_BeginPopup")
	begin_popup :: proc(str_id: cstring, flags: WindowFlags = {}) -> bool ---
	// return true if the modal is open, and you can start outputting to it.
	@(link_name = "ImGui_BeginPopupModal")
	begin_popup_modal :: proc(name: cstring, p_open: ^bool = nil, flags: WindowFlags = {}) -> bool ---
	// only call EndPopup() if BeginPopupXXX() returns true!
	@(link_name = "ImGui_EndPopup")
	end_popup :: proc() ---
	// Popups: open/close functions
	//  - OpenPopup(): set popup state to open. ImGuiPopupFlags are available for opening options.
	//  - If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.
	//  - CloseCurrentPopup(): use inside the BeginPopup()/EndPopup() scope to close manually.
	//  - CloseCurrentPopup() is called by default by Selectable()/MenuItem() when activated (FIXME: need some options).
	//  - Use ImGuiPopupFlags_NoOpenOverExistingPopup to avoid opening a popup if there's already one at the same level. This is equivalent to e.g. testing for !IsAnyPopupOpen() prior to OpenPopup().
	//  - Use IsWindowAppearing() after BeginPopup() to tell if a window just opened.
	//  - IMPORTANT: Notice that for OpenPopupOnItemClick() we exceptionally default flags to 1 (== ImGuiPopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter
	// call to mark popup as open (don't call every frame!).
	@(link_name = "ImGui_OpenPopup")
	open_popup :: proc(str_id: cstring, popup_flags: PopupFlags = {}) ---
	// id overload to facilitate calling from nested stacks
	@(link_name = "ImGui_OpenPopupID")
	open_popup_id :: proc(id: ID, popup_flags: PopupFlags = {}) ---
	// helper to open popup when clicked on last item. Default to ImGuiPopupFlags_MouseButtonRight == 1. (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors)
	@(link_name = "ImGui_OpenPopupOnItemClick")
	open_popup_on_item_click :: proc(str_id: cstring = nil, popup_flags: PopupFlags = {.MouseButtonRight}) ---
	// manually close the popup we have begin-ed into.
	@(link_name = "ImGui_CloseCurrentPopup")
	close_current_popup :: proc() ---
	// Popups: open+begin combined functions helpers
	//  - Helpers to do OpenPopup+BeginPopup where the Open action is triggered by e.g. hovering an item and right-clicking.
	//  - They are convenient to easily create context menus, hence the name.
	//  - IMPORTANT: Notice that BeginPopupContextXXX takes ImGuiPopupFlags just like OpenPopup() and unlike BeginPopup(). For full consistency, we may add ImGuiWindowFlags to the BeginPopupContextXXX functions in the future.
	//  - IMPORTANT: Notice that we exceptionally default their flags to 1 (== ImGuiPopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter, so if you add other flags remember to re-add the ImGuiPopupFlags_MouseButtonRight.
	// open+begin popup when clicked on last item. Use str_id==NULL to associate the popup to previous item. If you want to use that on a non-interactive item such as Text() you need to pass in an explicit ID here. read comments in .cpp!
	@(link_name = "ImGui_BeginPopupContextItem")
	begin_popup_context_item :: proc(str_id: cstring = nil, popup_flags: PopupFlags = {.MouseButtonRight}) -> bool ---
	// open+begin popup when clicked on current window.
	@(link_name = "ImGui_BeginPopupContextWindow")
	begin_popup_context_window :: proc(str_id: cstring = nil, popup_flags: PopupFlags = {.MouseButtonRight}) -> bool ---
	// open+begin popup when clicked in void (where there are no windows).
	@(link_name = "ImGui_BeginPopupContextVoid")
	begin_popup_context_void :: proc(str_id: cstring = nil, popup_flags: PopupFlags = {.MouseButtonRight}) -> bool ---
	// Popups: query functions
	//  - IsPopupOpen(): return true if the popup is open at the current BeginPopup() level of the popup stack.
	//  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId: return true if any popup is open at the current BeginPopup() level of the popup stack.
	//  - IsPopupOpen() with ImGuiPopupFlags_AnyPopupId + ImGuiPopupFlags_AnyPopupLevel: return true if any popup is open.
	// return true if the popup is open.
	@(link_name = "ImGui_IsPopupOpen")
	is_popup_open :: proc(str_id: cstring, flags: PopupFlags = {}) -> bool ---
	// Tables
	// - Full-featured replacement for old Columns API.
	// - See Demo->Tables for demo code. See top of imgui_tables.cpp for general commentary.
	// - See ImGuiTableFlags_ and ImGuiTableColumnFlags_ enums for a description of available flags.
	// The typical call flow is:
	// - 1. Call BeginTable(), early out if returning false.
	// - 2. Optionally call TableSetupColumn() to submit column name/flags/defaults.
	// - 3. Optionally call TableSetupScrollFreeze() to request scroll freezing of columns/rows.
	// - 4. Optionally call TableHeadersRow() to submit a header row. Names are pulled from TableSetupColumn() data.
	// - 5. Populate contents:
	//    - In most situations you can use TableNextRow() + TableSetColumnIndex(N) to start appending into a column.
	//    - If you are using tables as a sort of grid, where every column is holding the same type of contents,
	//      you may prefer using TableNextColumn() instead of TableNextRow() + TableSetColumnIndex().
	//      TableNextColumn() will automatically wrap-around into the next row if needed.
	//    - IMPORTANT: Comparatively to the old Columns() API, we need to call TableNextColumn() for the first column!
	//    - Summary of possible call flow:
	//        - TableNextRow() -> TableSetColumnIndex(0) -> Text("Hello 0") -> TableSetColumnIndex(1) -> Text("Hello 1")  // OK
	//        - TableNextRow() -> TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK
	//        -                   TableNextColumn()      -> Text("Hello 0") -> TableNextColumn()      -> Text("Hello 1")  // OK: TableNextColumn() automatically gets to next row!
	//        - TableNextRow()                           -> Text("Hello 0")                                               // Not OK! Missing TableSetColumnIndex() or TableNextColumn()! Text will not appear!
	// - 5. Call EndTable()
	@(link_name = "ImGui_BeginTable")
	begin_table :: proc(str_id: cstring, columns: i32, flags: TableFlags = {}, outer_size: Vec2 = Vec2{0.0, 0.0}, inner_width: f32 = 0.0) -> bool ---
	// only call EndTable() if BeginTable() returns true!
	@(link_name = "ImGui_EndTable")
	end_table :: proc() ---
	// append into the first cell of a new row.
	@(link_name = "ImGui_TableNextRow")
	table_next_row :: proc(row_flags: TableRowFlags = {}, min_row_height: f32 = 0.0) ---
	// append into the next column (or first column of next row if currently in last column). Return true when column is visible.
	@(link_name = "ImGui_TableNextColumn")
	table_next_column :: proc() -> bool ---
	// append into the specified column. Return true when column is visible.
	@(link_name = "ImGui_TableSetColumnIndex")
	table_set_column_index :: proc(column_n: i32) -> bool ---
	// Tables: Headers & Columns declaration
	// - Use TableSetupColumn() to specify label, resizing policy, default width/weight, id, various other flags etc.
	// - Use TableHeadersRow() to create a header row and automatically submit a TableHeader() for each column.
	//   Headers are required to perform: reordering, sorting, and opening the context menu.
	//   The context menu can also be made available in columns body using ImGuiTableFlags_ContextMenuInBody.
	// - You may manually submit headers using TableNextRow() + TableHeader() calls, but this is only useful in
	//   some advanced use cases (e.g. adding custom widgets in header row).
	// - Use TableSetupScrollFreeze() to lock columns/rows so they stay visible when scrolled.
	@(link_name = "ImGui_TableSetupColumn")
	table_setup_column :: proc(label: cstring, flags: TableColumnFlags = {}, init_width_or_weight: f32 = 0.0, user_id: ID = {}) ---
	// lock columns/rows so they stay visible when scrolled.
	@(link_name = "ImGui_TableSetupScrollFreeze")
	table_setup_scroll_freeze :: proc(cols: i32, rows: i32) ---
	// submit one header cell manually (rarely used)
	@(link_name = "ImGui_TableHeader")
	table_header :: proc(label: cstring) ---
	// submit a row with headers cells based on data provided to TableSetupColumn() + submit context menu
	@(link_name = "ImGui_TableHeadersRow")
	table_headers_row :: proc() ---
	// submit a row with angled headers for every column with the ImGuiTableColumnFlags_AngledHeader flag. MUST BE FIRST ROW.
	@(link_name = "ImGui_TableAngledHeadersRow")
	table_angled_headers_row :: proc() ---
	// Tables: Sorting & Miscellaneous functions
	// - Sorting: call TableGetSortSpecs() to retrieve latest sort specs for the table. NULL when not sorting.
	//   When 'sort_specs->SpecsDirty == true' you should sort your data. It will be true when sorting specs have
	//   changed since last call, or the first time. Make sure to set 'SpecsDirty = false' after sorting,
	//   else you may wastefully sort your data every frame!
	// - Functions args 'int column_n' treat the default value of -1 as the same as passing the current column index.
	// get latest sort specs for the table (NULL if not sorting).  Lifetime: don't hold on this pointer over multiple frames or past any subsequent call to BeginTable().
	@(link_name = "ImGui_TableGetSortSpecs")
	table_get_sort_specs :: proc() -> ^TableSortSpecs ---
	// return number of columns (value passed to BeginTable)
	@(link_name = "ImGui_TableGetColumnCount")
	table_get_column_count :: proc() -> i32 ---
	// return current column index.
	@(link_name = "ImGui_TableGetColumnIndex")
	table_get_column_index :: proc() -> i32 ---
	// return current row index.
	@(link_name = "ImGui_TableGetRowIndex")
	table_get_row_index :: proc() -> i32 ---
	// return "" if column didn't have a name declared by TableSetupColumn(). Pass -1 to use current column.
	@(link_name = "ImGui_TableGetColumnName")
	table_get_column_name :: proc(column_n: i32 = -1) -> cstring ---
	// return column flags so you can query their Enabled/Visible/Sorted/Hovered status flags. Pass -1 to use current column.
	@(link_name = "ImGui_TableGetColumnFlags")
	table_get_column_flags :: proc(column_n: i32 = -1) -> TableColumnFlags ---
	// change user accessible enabled/disabled state of a column. Set to false to hide the column. User can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGuiTableFlags_ContextMenuInBody)
	@(link_name = "ImGui_TableSetColumnEnabled")
	table_set_column_enabled :: proc(column_n: i32, v: bool) ---
	// return hovered column. return -1 when table is not hovered. return columns_count if the unused space at the right of visible columns is hovered. Can also use (TableGetColumnFlags() & ImGuiTableColumnFlags_IsHovered) instead.
	@(link_name = "ImGui_TableGetHoveredColumn")
	table_get_hovered_column :: proc() -> i32 ---
	// change the color of a cell, row, or column. See ImGuiTableBgTarget_ flags for details.
	@(link_name = "ImGui_TableSetBgColor")
	table_set_bg_color :: proc(target: TableBgTarget, color: u32, column_n: i32 = -1) ---
	// Legacy Columns API (prefer using Tables!)
	// - You can also use SameLine(pos_x) to mimic simplified columns.
	@(link_name = "ImGui_Columns")
	columns :: proc(count: i32 = 1, id: cstring = nil, borders: bool = true) ---
	// next column, defaults to current row or next row if the current row is finished
	@(link_name = "ImGui_NextColumn")
	next_column :: proc() ---
	// get current column index
	@(link_name = "ImGui_GetColumnIndex")
	get_column_index :: proc() -> i32 ---
	// get column width (in pixels). pass -1 to use current column
	@(link_name = "ImGui_GetColumnWidth")
	get_column_width :: proc(column_index: i32 = -1) -> f32 ---
	// set column width (in pixels). pass -1 to use current column
	@(link_name = "ImGui_SetColumnWidth")
	set_column_width :: proc(column_index: i32, width: f32) ---
	// get position of column line (in pixels, from the left side of the contents region). pass -1 to use current column, otherwise 0..GetColumnsCount() inclusive. column 0 is typically 0.0f
	@(link_name = "ImGui_GetColumnOffset")
	get_column_offset :: proc(column_index: i32 = -1) -> f32 ---
	// set position of column line (in pixels, from the left side of the contents region). pass -1 to use current column
	@(link_name = "ImGui_SetColumnOffset")
	set_column_offset :: proc(column_index: i32, offset_x: f32) ---
	@(link_name = "ImGui_GetColumnsCount")
	get_columns_count :: proc() -> i32 ---
	// Tab Bars, Tabs
	// - Note: Tabs are automatically created by the docking system (when in 'docking' branch). Use this to create tab bars/tabs yourself.
	// create and append into a TabBar
	@(link_name = "ImGui_BeginTabBar")
	begin_tab_bar :: proc(str_id: cstring, flags: TabBarFlags = {}) -> bool ---
	// only call EndTabBar() if BeginTabBar() returns true!
	@(link_name = "ImGui_EndTabBar")
	end_tab_bar :: proc() ---
	// create a Tab. Returns true if the Tab is selected.
	@(link_name = "ImGui_BeginTabItem")
	begin_tab_item :: proc(label: cstring, p_open: ^bool = nil, flags: TabItemFlags = {}) -> bool ---
	// only call EndTabItem() if BeginTabItem() returns true!
	@(link_name = "ImGui_EndTabItem")
	end_tab_item :: proc() ---
	// create a Tab behaving like a button. return true when clicked. cannot be selected in the tab bar.
	@(link_name = "ImGui_TabItemButton")
	tab_item_button :: proc(label: cstring, flags: TabItemFlags = {}) -> bool ---
	// notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after BeginTabBar() and before Tab submissions. Otherwise call with a window name.
	@(link_name = "ImGui_SetTabItemClosed")
	set_tab_item_closed :: proc(tab_or_docked_window_label: cstring) ---
	// Logging/Capture
	// - All text output from the interface can be captured into tty/file/clipboard. By default, tree nodes are automatically opened during logging.
	// start logging to tty (stdout)
	@(link_name = "ImGui_LogToTTY")
	log_to_tty :: proc(auto_open_depth: i32 = -1) ---
	// start logging to file
	@(link_name = "ImGui_LogToFile")
	log_to_file :: proc(auto_open_depth: i32 = -1, filename: cstring = nil) ---
	// start logging to OS clipboard
	@(link_name = "ImGui_LogToClipboard")
	log_to_clipboard :: proc(auto_open_depth: i32 = -1) ---
	// stop logging (close file, etc.)
	@(link_name = "ImGui_LogFinish")
	log_finish :: proc() ---
	// helper to display buttons for logging to tty/file/clipboard
	@(link_name = "ImGui_LogButtons")
	log_buttons :: proc() ---
	// pass text data straight to log (without being displayed)
	@(link_name = "ImGui_LogText")
	log_text :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// Drag and Drop
	// - On source items, call BeginDragDropSource(), if it returns true also call SetDragDropPayload() + EndDragDropSource().
	// - On target candidates, call BeginDragDropTarget(), if it returns true also call AcceptDragDropPayload() + EndDragDropTarget().
	// - If you stop calling BeginDragDropSource() the payload is preserved however it won't have a preview tooltip (we currently display a fallback "..." tooltip, see #1725)
	// - An item can be both drag source and drop target.
	// call after submitting an item which may be dragged. when this return true, you can call SetDragDropPayload() + EndDragDropSource()
	@(link_name = "ImGui_BeginDragDropSource")
	begin_drag_drop_source :: proc(flags: DragDropFlags = {}) -> bool ---
	// type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui. Return true when payload has been accepted.
	@(link_name = "ImGui_SetDragDropPayload")
	set_drag_drop_payload :: proc(type: cstring, data: rawptr, sz: uint, cond: Cond = {}) -> bool ---
	// only call EndDragDropSource() if BeginDragDropSource() returns true!
	@(link_name = "ImGui_EndDragDropSource")
	end_drag_drop_source :: proc() ---
	// call after submitting an item that may receive a payload. If this returns true, you can call AcceptDragDropPayload() + EndDragDropTarget()
	@(link_name = "ImGui_BeginDragDropTarget")
	begin_drag_drop_target :: proc() -> bool ---
	// accept contents of a given type. If ImGuiDragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.
	@(link_name = "ImGui_AcceptDragDropPayload")
	accept_drag_drop_payload :: proc(type: cstring, flags: DragDropFlags = {}) -> ^Payload ---
	// only call EndDragDropTarget() if BeginDragDropTarget() returns true!
	@(link_name = "ImGui_EndDragDropTarget")
	end_drag_drop_target :: proc() ---
	// peek directly into the current payload from anywhere. returns NULL when drag and drop is finished or inactive. use ImGuiPayload::IsDataType() to test for the payload type.
	@(link_name = "ImGui_GetDragDropPayload")
	get_drag_drop_payload :: proc() -> ^Payload ---
	// Disabling [BETA API]
	// - Disable all user interactions and dim items visuals (applying style.DisabledAlpha over current colors)
	// - Those can be nested but it cannot be used to enable an already disabled section (a single BeginDisabled(true) in the stack is enough to keep everything disabled)
	// - Tooltips windows by exception are opted out of disabling.
	// - BeginDisabled(false)/EndDisabled() essentially does nothing but is provided to facilitate use of boolean expressions (as a micro-optimization: if you have tens of thousands of BeginDisabled(false)/EndDisabled() pairs, you might want to reformulate your code to avoid making those calls)
	@(link_name = "ImGui_BeginDisabled")
	begin_disabled :: proc(disabled: bool = true) ---
	@(link_name = "ImGui_EndDisabled")
	end_disabled :: proc() ---
	// Clipping
	// - Mouse hovering is affected by ImGui::PushClipRect() calls, unlike direct calls to ImDrawList::PushClipRect() which are render only.
	@(link_name = "ImGui_PushClipRect")
	push_clip_rect :: proc(clip_rect_min: Vec2, clip_rect_max: Vec2, intersect_with_current_clip_rect: bool) ---
	@(link_name = "ImGui_PopClipRect")
	pop_clip_rect :: proc() ---
	// Focus, Activation
	// make last item the default focused item of of a newly appearing window.
	@(link_name = "ImGui_SetItemDefaultFocus")
	set_item_default_focus :: proc() ---
	// focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.
	@(link_name = "ImGui_SetKeyboardFocusHere")
	set_keyboard_focus_here :: proc(offset: i32 = 0) ---
	// Keyboard/Gamepad Navigation
	// alter visibility of keyboard/gamepad cursor. by default: show when using an arrow key, hide when clicking with mouse.
	@(link_name = "ImGui_SetNavCursorVisible")
	set_nav_cursor_visible :: proc(visible: bool) ---
	// Overlapping mode
	// allow next item to be overlapped by a subsequent item. Useful with invisible buttons, selectable, treenode covering an area where subsequent items may need to be added. Note that both Selectable() and TreeNode() have dedicated flags doing this.
	@(link_name = "ImGui_SetNextItemAllowOverlap")
	set_next_item_allow_overlap :: proc() ---
	// Item/Widgets Utilities and Query Functions
	// - Most of the functions are referring to the previous Item that has been submitted.
	// - See Demo Window under "Widgets->Querying Status" for an interactive visualization of most of those functions.
	// is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGuiHoveredFlags for more options.
	@(link_name = "ImGui_IsItemHovered")
	is_item_hovered :: proc(flags: HoveredFlags = {}) -> bool ---
	// is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
	@(link_name = "ImGui_IsItemActive")
	is_item_active :: proc() -> bool ---
	// is the last item focused for keyboard/gamepad navigation?
	@(link_name = "ImGui_IsItemFocused")
	is_item_focused :: proc() -> bool ---
	// is the last item hovered and mouse clicked on? (**)  == IsMouseClicked(mouse_button) && IsItemHovered()Important. (**) this is NOT equivalent to the behavior of e.g. Button(). Read comments in function definition.
	@(link_name = "ImGui_IsItemClicked")
	is_item_clicked :: proc(mouse_button: MouseButton = {}) -> bool ---
	// is the last item visible? (items may be out of sight because of clipping/scrolling)
	@(link_name = "ImGui_IsItemVisible")
	is_item_visible :: proc() -> bool ---
	// did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
	@(link_name = "ImGui_IsItemEdited")
	is_item_edited :: proc() -> bool ---
	// was the last item just made active (item was previously inactive).
	@(link_name = "ImGui_IsItemActivated")
	is_item_activated :: proc() -> bool ---
	// was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that require continuous editing.
	@(link_name = "ImGui_IsItemDeactivated")
	is_item_deactivated :: proc() -> bool ---
	// was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that require continuous editing. Note that you may get false positives (some widgets such as Combo()/ListBox()/Selectable() will return true even when clicking an already selected item).
	@(link_name = "ImGui_IsItemDeactivatedAfterEdit")
	is_item_deactivated_after_edit :: proc() -> bool ---
	// was the last item open state toggled? set by TreeNode().
	@(link_name = "ImGui_IsItemToggledOpen")
	is_item_toggled_open :: proc() -> bool ---
	// is any item hovered?
	@(link_name = "ImGui_IsAnyItemHovered")
	is_any_item_hovered :: proc() -> bool ---
	// is any item active?
	@(link_name = "ImGui_IsAnyItemActive")
	is_any_item_active :: proc() -> bool ---
	// is any item focused?
	@(link_name = "ImGui_IsAnyItemFocused")
	is_any_item_focused :: proc() -> bool ---
	// get ID of last item (~~ often same ImGui::GetID(label) beforehand)
	@(link_name = "ImGui_GetItemID")
	get_item_id :: proc() -> ID ---
	// get upper-left bounding rectangle of the last item (screen space)
	@(link_name = "ImGui_GetItemRectMin")
	get_item_rect_min :: proc() -> Vec2 ---
	// get lower-right bounding rectangle of the last item (screen space)
	@(link_name = "ImGui_GetItemRectMax")
	get_item_rect_max :: proc() -> Vec2 ---
	// get size of last item
	@(link_name = "ImGui_GetItemRectSize")
	get_item_rect_size :: proc() -> Vec2 ---
	// Viewports
	// - Currently represents the Platform Window created by the application which is hosting our Dear ImGui windows.
	// - In 'docking' branch with multi-viewport enabled, we extend this concept to have multiple active viewports.
	// - In the future we will extend this concept further to also represent Platform Monitor and support a "no main platform window" operation mode.
	// return primary/default viewport. This can never be NULL.
	@(link_name = "ImGui_GetMainViewport")
	get_main_viewport :: proc() -> ^Viewport ---
	// Background/Foreground Draw Lists
	// this draw list will be the first rendered one. Useful to quickly draw shapes/text behind dear imgui contents.
	@(link_name = "ImGui_GetBackgroundDrawList")
	get_background_draw_list :: proc() -> ^DrawList ---
	// this draw list will be the last rendered one. Useful to quickly draw shapes/text over dear imgui contents.
	@(link_name = "ImGui_GetForegroundDrawList")
	get_foreground_draw_list :: proc() -> ^DrawList ---
	// Miscellaneous Utilities
	// test if rectangle (of given size, starting from cursor position) is visible / not clipped.
	@(link_name = "ImGui_IsRectVisibleBySize")
	is_rect_visible_by_size :: proc(size: Vec2) -> bool ---
	// test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
	@(link_name = "ImGui_IsRectVisible")
	is_rect_visible :: proc(rect_min: Vec2, rect_max: Vec2) -> bool ---
	// get global imgui time. incremented by io.DeltaTime every frame.
	@(link_name = "ImGui_GetTime")
	get_time :: proc() -> f64 ---
	// get global imgui frame count. incremented by 1 every frame.
	@(link_name = "ImGui_GetFrameCount")
	get_frame_count :: proc() -> i32 ---
	// you may use this when creating your own ImDrawList instances.
	@(link_name = "ImGui_GetDrawListSharedData")
	get_draw_list_shared_data :: proc() -> ^DrawListSharedData ---
	// get a string corresponding to the enum value (for display, saving, etc.).
	@(link_name = "ImGui_GetStyleColorName")
	get_style_color_name :: proc(idx: Col) -> cstring ---
	// replace current window storage with our own (if you want to manipulate it yourself, typically clear subsection of it)
	@(link_name = "ImGui_SetStateStorage")
	set_state_storage :: proc(storage: ^Storage) ---
	@(link_name = "ImGui_GetStateStorage")
	get_state_storage :: proc() -> ^Storage ---
	// Text Utilities
	@(link_name = "ImGui_CalcTextSize")
	calc_text_size :: proc(text: cstring, text_end: cstring = nil, hide_text_after_double_hash: bool = false, wrap_width: f32 = -1.0) -> Vec2 ---
	// Color Utilities
	@(link_name = "ImGui_ColorConvertU32ToFloat4")
	color_convert_u32to_float4 :: proc(_in: u32) -> Vec4 ---
	@(link_name = "ImGui_ColorConvertFloat4ToU32")
	color_convert_float4to_u32 :: proc(_in: Vec4) -> u32 ---
	@(link_name = "ImGui_ColorConvertRGBtoHSV")
	color_convert_rg_bto_hsv :: proc(r: f32, g: f32, b: f32, out_h: ^f32, out_s: ^f32, out_v: ^f32) ---
	@(link_name = "ImGui_ColorConvertHSVtoRGB")
	color_convert_hs_vto_rgb :: proc(h: f32, s: f32, v: f32, out_r: ^f32, out_g: ^f32, out_b: ^f32) ---
	// Inputs Utilities: Keyboard/Mouse/Gamepad
	// - the ImGuiKey enum contains all possible keyboard, mouse and gamepad inputs (e.g. ImGuiKey_A, ImGuiKey_MouseLeft, ImGuiKey_GamepadDpadUp...).
	// - (legacy: before v1.87, we used ImGuiKey to carry native/user indices as defined by each backends. This was obsoleted in 1.87 (2022-02) and completely removed in 1.91.5 (2024-11). See https://github.com/ocornut/imgui/issues/4921)
	// - (legacy: any use of ImGuiKey will assert when key < 512 to detect passing legacy native/user indices)
	// is key being held.
	@(link_name = "ImGui_IsKeyDown")
	is_key_down :: proc(key: Key) -> bool ---
	// was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRate
	@(link_name = "ImGui_IsKeyPressed")
	is_key_pressed :: proc(key: Key, repeat: bool = true) -> bool ---
	// was key released (went from Down to !Down)?
	@(link_name = "ImGui_IsKeyReleased")
	is_key_released :: proc(key: Key) -> bool ---
	// was key chord (mods + key) pressed, e.g. you can pass 'ImGuiMod_Ctrl | ImGuiKey_S' as a key-chord. This doesn't do any routing or focus check, please consider using Shortcut() function instead.
	@(link_name = "ImGui_IsKeyChordPressed")
	is_key_chord_pressed :: proc(key_chord: KeyChord) -> bool ---
	// uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
	@(link_name = "ImGui_GetKeyPressedAmount")
	get_key_pressed_amount :: proc(key: Key, repeat_delay: f32, rate: f32) -> i32 ---
	// [DEBUG] returns English name of the key. Those names a provided for debugging purpose and are not meant to be saved persistently not compared.
	@(link_name = "ImGui_GetKeyName")
	get_key_name :: proc(key: Key) -> cstring ---
	// Override io.WantCaptureKeyboard flag next frame (said flag is left for your application to handle, typically when true it instructs your app to ignore inputs). e.g. force capture keyboard when your widget is being hovered. This is equivalent to setting "io.WantCaptureKeyboard = want_capture_keyboard"; after the next NewFrame() call.
	@(link_name = "ImGui_SetNextFrameWantCaptureKeyboard")
	set_next_frame_want_capture_keyboard :: proc(want_capture_keyboard: bool) ---
	// Inputs Utilities: Shortcut Testing & Routing [BETA]
	// - ImGuiKeyChord = a ImGuiKey + optional ImGuiMod_Alt/ImGuiMod_Ctrl/ImGuiMod_Shift/ImGuiMod_Super.
	//       ImGuiKey_C                          // Accepted by functions taking ImGuiKey or ImGuiKeyChord arguments)
	//       ImGuiMod_Ctrl | ImGuiKey_C          // Accepted by functions taking ImGuiKeyChord arguments)
	//   only ImGuiMod_XXX values are legal to combine with an ImGuiKey. You CANNOT combine two ImGuiKey values.
	// - The general idea is that several callers may register interest in a shortcut, and only one owner gets it.
	//      Parent   -> call Shortcut(Ctrl+S)    // When Parent is focused, Parent gets the shortcut.
	//        Child1 -> call Shortcut(Ctrl+S)    // When Child1 is focused, Child1 gets the shortcut (Child1 overrides Parent shortcuts)
	//        Child2 -> no call                  // When Child2 is focused, Parent gets the shortcut.
	//   The whole system is order independent, so if Child1 makes its calls before Parent, results will be identical.
	//   This is an important property as it facilitate working with foreign code or larger codebase.
	// - To understand the difference:
	//   - IsKeyChordPressed() compares mods and call IsKeyPressed() -> function has no side-effect.
	//   - Shortcut() submits a route, routes are resolved, if it currently can be routed it calls IsKeyChordPressed() -> function has (desirable) side-effects as it can prevents another call from getting the route.
	// - Visualize registered routes in 'Metrics/Debugger->Inputs'.
	@(link_name = "ImGui_Shortcut")
	shortcut :: proc(key_chord: KeyChord, flags: InputFlags = {}) -> bool ---
	@(link_name = "ImGui_SetNextItemShortcut")
	set_next_item_shortcut :: proc(key_chord: KeyChord, flags: InputFlags = {}) ---
	// Inputs Utilities: Key/Input Ownership [BETA]
	// - One common use case would be to allow your items to disable standard inputs behaviors such
	//   as Tab or Alt key handling, Mouse Wheel scrolling, etc.
	//   e.g. Button(...); SetItemKeyOwner(ImGuiKey_MouseWheelY); to make hovering/activating a button disable wheel for scrolling.
	// - Reminder ImGuiKey enum include access to mouse buttons and gamepad, so key ownership can apply to them.
	// - Many related features are still in imgui_internal.h. For instance, most IsKeyXXX()/IsMouseXXX() functions have an owner-id-aware version.
	// Set key owner to last item ID if it is hovered or active. Equivalent to 'if (IsItemHovered() || IsItemActive()) { SetKeyOwner(key, GetItemID());'.
	@(link_name = "ImGui_SetItemKeyOwner")
	set_item_key_owner :: proc(key: Key) ---
	// Inputs Utilities: Mouse
	// - To refer to a mouse button, you may use named enums in your code e.g. ImGuiMouseButton_Left, ImGuiMouseButton_Right.
	// - You can also use regular integer: it is forever guaranteed that 0=Left, 1=Right, 2=Middle.
	// - Dragging operations are only reported after mouse has moved a certain distance away from the initial clicking position (see 'lock_threshold' and 'io.MouseDraggingThreshold')
	// is mouse button held?
	@(link_name = "ImGui_IsMouseDown")
	is_mouse_down :: proc(button: MouseButton) -> bool ---
	// did mouse button clicked? (went from !Down to Down). Same as GetMouseClickedCount() == 1.
	@(link_name = "ImGui_IsMouseClicked")
	is_mouse_clicked :: proc(button: MouseButton, repeat: bool = false) -> bool ---
	// did mouse button released? (went from Down to !Down)
	@(link_name = "ImGui_IsMouseReleased")
	is_mouse_released :: proc(button: MouseButton) -> bool ---
	// did mouse button double-clicked? Same as GetMouseClickedCount() == 2. (note that a double-click will also report IsMouseClicked() == true)
	@(link_name = "ImGui_IsMouseDoubleClicked")
	is_mouse_double_clicked :: proc(button: MouseButton) -> bool ---
	// return the number of successive mouse-clicks at the time where a click happen (otherwise 0).
	@(link_name = "ImGui_GetMouseClickedCount")
	get_mouse_clicked_count :: proc(button: MouseButton) -> i32 ---
	// is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.
	@(link_name = "ImGui_IsMouseHoveringRect")
	is_mouse_hovering_rect :: proc(r_min: Vec2, r_max: Vec2, clip: bool = true) -> bool ---
	// by convention we use (-FLT_MAX,-FLT_MAX) to denote that there is no mouse available
	@(link_name = "ImGui_IsMousePosValid")
	is_mouse_pos_valid :: proc(mouse_pos: ^Vec2 = nil) -> bool ---
	// [WILL OBSOLETE] is any mouse button held? This was designed for backends, but prefer having backend maintain a mask of held mouse buttons, because upcoming input queue system will make this invalid.
	@(link_name = "ImGui_IsAnyMouseDown")
	is_any_mouse_down :: proc() -> bool ---
	// shortcut to ImGui::GetIO().MousePos provided by user, to be consistent with other calls
	@(link_name = "ImGui_GetMousePos")
	get_mouse_pos :: proc() -> Vec2 ---
	// retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
	@(link_name = "ImGui_GetMousePosOnOpeningCurrentPopup")
	get_mouse_pos_on_opening_current_popup :: proc() -> Vec2 ---
	// is mouse dragging? (uses io.MouseDraggingThreshold if lock_threshold < 0.0f)
	@(link_name = "ImGui_IsMouseDragging")
	is_mouse_dragging :: proc(button: MouseButton, lock_threshold: f32 = -1.0) -> bool ---
	// return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (uses io.MouseDraggingThreshold if lock_threshold < 0.0f)
	@(link_name = "ImGui_GetMouseDragDelta")
	get_mouse_drag_delta :: proc(button: MouseButton = {}, lock_threshold: f32 = -1.0) -> Vec2 ---
	//
	@(link_name = "ImGui_ResetMouseDragDelta")
	reset_mouse_drag_delta :: proc(button: MouseButton = {}) ---
	// get desired mouse cursor shape. Important: reset in ImGui::NewFrame(), this is updated during the frame. valid before Render(). If you use software rendering by setting io.MouseDrawCursor ImGui will render those for you
	@(link_name = "ImGui_GetMouseCursor")
	get_mouse_cursor :: proc() -> MouseCursor ---
	// set desired mouse cursor shape
	@(link_name = "ImGui_SetMouseCursor")
	set_mouse_cursor :: proc(cursor_type: MouseCursor) ---
	// Override io.WantCaptureMouse flag next frame (said flag is left for your application to handle, typical when true it instucts your app to ignore inputs). This is equivalent to setting "io.WantCaptureMouse = want_capture_mouse;" after the next NewFrame() call.
	@(link_name = "ImGui_SetNextFrameWantCaptureMouse")
	set_next_frame_want_capture_mouse :: proc(want_capture_mouse: bool) ---
	// Clipboard Utilities
	// - Also see the LogToClipboard() function to capture GUI into clipboard, or easily output text data to the clipboard.
	@(link_name = "ImGui_GetClipboardText")
	get_clipboard_text :: proc() -> cstring ---
	@(link_name = "ImGui_SetClipboardText")
	set_clipboard_text :: proc(text: cstring) ---
	// Settings/.Ini Utilities
	// - The disk functions are automatically called if io.IniFilename != NULL (default is "imgui.ini").
	// - Set io.IniFilename to NULL to load/save manually. Read io.WantSaveIniSettings description about handling .ini saving manually.
	// - Important: default value "imgui.ini" is relative to current working dir! Most apps will want to lock this to an absolute path (e.g. same path as executables).
	// call after CreateContext() and before the first call to NewFrame(). NewFrame() automatically calls LoadIniSettingsFromDisk(io.IniFilename).
	@(link_name = "ImGui_LoadIniSettingsFromDisk")
	load_ini_settings_from_disk :: proc(ini_filename: cstring) ---
	// call after CreateContext() and before the first call to NewFrame() to provide .ini data from your own data source.
	@(link_name = "ImGui_LoadIniSettingsFromMemory")
	load_ini_settings_from_memory :: proc(ini_data: cstring, ini_size: uint = {}) ---
	// this is automatically called (if io.IniFilename is not empty) a few seconds after any modification that should be reflected in the .ini file (and also by DestroyContext).
	@(link_name = "ImGui_SaveIniSettingsToDisk")
	save_ini_settings_to_disk :: proc(ini_filename: cstring) ---
	// return a zero-terminated string with the .ini data which you can save by your own mean. call when io.WantSaveIniSettings is set, then save data by your own mean and clear io.WantSaveIniSettings.
	@(link_name = "ImGui_SaveIniSettingsToMemory")
	save_ini_settings_to_memory :: proc(out_ini_size: ^uint = nil) -> cstring ---
	// Debug Utilities
	// - Your main debugging friend is the ShowMetricsWindow() function, which is also accessible from Demo->Tools->Metrics Debugger
	@(link_name = "ImGui_DebugTextEncoding")
	debug_text_encoding :: proc(text: cstring) ---
	@(link_name = "ImGui_DebugFlashStyleColor")
	debug_flash_style_color :: proc(idx: Col) ---
	@(link_name = "ImGui_DebugStartItemPicker")
	debug_start_item_picker :: proc() ---
	// This is called by IMGUI_CHECKVERSION() macro.
	@(link_name = "ImGui_DebugCheckVersionAndDataLayout")
	debug_check_version_and_data_layout :: proc(version_str: cstring, sz_io: uint, sz_style: uint, sz_vec2: uint, sz_vec4: uint, sz_drawvert: uint, sz_drawidx: uint) -> bool ---
	// Call via IMGUI_DEBUG_LOG() for maximum stripping in caller code!
	@(link_name = "ImGui_DebugLog")
	debug_log :: proc(fmt: cstring, #c_vararg args: ..any) ---
	// Memory Allocators
	// - Those functions are not reliant on the current context.
	// - DLL users: heaps and globals are not shared across DLL boundaries! You will need to call SetCurrentContext() + SetAllocatorFunctions()
	//   for each static/DLL boundary you are calling from. Read "Context and Memory Allocators" section of imgui.cpp for more details.
	@(link_name = "ImGui_SetAllocatorFunctions")
	set_allocator_functions :: proc(alloc_func: MemAllocFunc, free_func: MemFreeFunc, user_data: rawptr = nil) ---
	@(link_name = "ImGui_GetAllocatorFunctions")
	get_allocator_functions :: proc(p_alloc_func: ^MemAllocFunc, p_free_func: ^MemFreeFunc, p_user_data: ^rawptr) ---
	@(link_name = "ImGui_MemAlloc")
	mem_alloc :: proc(size: uint) -> rawptr ---
	@(link_name = "ImGui_MemFree")
	mem_free :: proc(ptr: rawptr) ---
	// Construct a zero-size ImVector<> (of any type). This is primarily useful when calling ImFontGlyphRangesBuilder_BuildRanges()
	@(link_name = "ImVector_Construct")
	vector_construct :: proc(vector: rawptr) ---
	// Destruct an ImVector<> (of any type). Important: Frees the vector memory but does not call destructors on contained objects (if they have them)
	@(link_name = "ImVector_Destruct")
	vector_destruct :: proc(vector: rawptr) ---
	@(link_name = "ImGuiStyle_ScaleAllSizes")
	style_scale_all_sizes :: proc(self: ^Style, scale_factor: f32) ---
	// Input Functions
	// Queue a new key down/up event. Key should be "translated" (as in, generally ImGuiKey_A matches the key end-user would use to emit an 'A' character)
	@(link_name = "ImGuiIO_AddKeyEvent")
	io_add_key_event :: proc(self: ^IO, key: Key, down: bool) ---
	// Queue a new key down/up event for analog values (e.g. ImGuiKey_Gamepad_ values). Dead-zones should be handled by the backend.
	@(link_name = "ImGuiIO_AddKeyAnalogEvent")
	io_add_key_analog_event :: proc(self: ^IO, key: Key, down: bool, v: f32) ---
	// Queue a mouse position update. Use -FLT_MAX,-FLT_MAX to signify no mouse (e.g. app not focused and not hovered)
	@(link_name = "ImGuiIO_AddMousePosEvent")
	io_add_mouse_pos_event :: proc(self: ^IO, x: f32, y: f32) ---
	// Queue a mouse button change
	@(link_name = "ImGuiIO_AddMouseButtonEvent")
	io_add_mouse_button_event :: proc(self: ^IO, button: i32, down: bool) ---
	// Queue a mouse wheel update. wheel_y<0: scroll down, wheel_y>0: scroll up, wheel_x<0: scroll right, wheel_x>0: scroll left.
	@(link_name = "ImGuiIO_AddMouseWheelEvent")
	io_add_mouse_wheel_event :: proc(self: ^IO, wheel_x: f32, wheel_y: f32) ---
	// Queue a mouse source change (Mouse/TouchScreen/Pen)
	@(link_name = "ImGuiIO_AddMouseSourceEvent")
	io_add_mouse_source_event :: proc(self: ^IO, source: MouseSource) ---
	// Queue a gain/loss of focus for the application (generally based on OS/platform focus of your window)
	@(link_name = "ImGuiIO_AddFocusEvent")
	io_add_focus_event :: proc(self: ^IO, focused: bool) ---
	// Queue a new character input
	@(link_name = "ImGuiIO_AddInputCharacter")
	io_add_input_character :: proc(self: ^IO, c: u32) ---
	// Queue a new character input from a UTF-16 character, it can be a surrogate
	@(link_name = "ImGuiIO_AddInputCharacterUTF16")
	io_add_input_character_utf16 :: proc(self: ^IO, c: Wchar16) ---
	// Queue a new characters input from a UTF-8 string
	@(link_name = "ImGuiIO_AddInputCharactersUTF8")
	io_add_input_characters_utf8 :: proc(self: ^IO, str: cstring) ---
	// [Optional] Specify index for legacy <1.87 IsKeyXXX() functions with native indices + specify native keycode, scancode.
	@(link_name = "ImGuiIO_SetKeyEventNativeData")
	io_set_key_event_native_data :: proc(self: ^IO, key: Key, native_keycode: i32, native_scancode: i32, native_legacy_index: i32 = -1) ---
	// Set master flag for accepting key/mouse/text events (default to true). Useful if you have native dialog boxes that are interrupting your application loop/refresh, and you want to disable events being queued while your app is frozen.
	@(link_name = "ImGuiIO_SetAppAcceptingEvents")
	io_set_app_accepting_events :: proc(self: ^IO, accepting_events: bool) ---
	// Clear all incoming events.
	@(link_name = "ImGuiIO_ClearEventsQueue")
	io_clear_events_queue :: proc(self: ^IO) ---
	// Clear current keyboard/gamepad state + current frame text input buffer. Equivalent to releasing all keys/buttons.
	@(link_name = "ImGuiIO_ClearInputKeys")
	io_clear_input_keys :: proc(self: ^IO) ---
	// Clear current mouse state.
	@(link_name = "ImGuiIO_ClearInputMouse")
	io_clear_input_mouse :: proc(self: ^IO) ---
	@(link_name = "ImGuiInputTextCallbackData_DeleteChars")
	input_text_callback_data_delete_chars :: proc(self: ^InputTextCallbackData, pos: i32, bytes_count: i32) ---
	@(link_name = "ImGuiInputTextCallbackData_InsertChars")
	input_text_callback_data_insert_chars :: proc(self: ^InputTextCallbackData, pos: i32, text: cstring, text_end: cstring = nil) ---
	@(link_name = "ImGuiInputTextCallbackData_SelectAll")
	input_text_callback_data_select_all :: proc(self: ^InputTextCallbackData) ---
	@(link_name = "ImGuiInputTextCallbackData_ClearSelection")
	input_text_callback_data_clear_selection :: proc(self: ^InputTextCallbackData) ---
	@(link_name = "ImGuiInputTextCallbackData_HasSelection")
	input_text_callback_data_has_selection :: proc(self: ^InputTextCallbackData) -> bool ---
	@(link_name = "ImGuiPayload_Clear")
	payload_clear :: proc(self: ^Payload) ---
	@(link_name = "ImGuiPayload_IsDataType")
	payload_is_data_type :: proc(self: ^Payload, type: cstring) -> bool ---
	@(link_name = "ImGuiPayload_IsPreview")
	payload_is_preview :: proc(self: ^Payload) -> bool ---
	@(link_name = "ImGuiPayload_IsDelivery")
	payload_is_delivery :: proc(self: ^Payload) -> bool ---
	@(link_name = "ImGuiTextFilter_ImGuiTextRange_empty")
	text_filter_text_range_empty :: proc(self: ^TextFilterTextRange) -> bool ---
	@(link_name = "ImGuiTextFilter_ImGuiTextRange_split")
	text_filter_text_range_split :: proc(self: ^TextFilterTextRange, separator: u8, out: ^VectorTextFilterTextRange) ---
	// Helper calling InputText+Build
	@(link_name = "ImGuiTextFilter_Draw")
	text_filter_draw :: proc(self: ^TextFilter, label: cstring = "Filter (inc,-exc)", width: f32 = 0.0) -> bool ---
	@(link_name = "ImGuiTextFilter_PassFilter")
	text_filter_pass_filter :: proc(self: ^TextFilter, text: cstring, text_end: cstring = nil) -> bool ---
	@(link_name = "ImGuiTextFilter_Build")
	text_filter_build :: proc(self: ^TextFilter) ---
	@(link_name = "ImGuiTextFilter_Clear")
	text_filter_clear :: proc(self: ^TextFilter) ---
	@(link_name = "ImGuiTextFilter_IsActive")
	text_filter_is_active :: proc(self: ^TextFilter) -> bool ---
	@(link_name = "ImGuiTextBuffer_begin")
	text_buffer_begin :: proc(self: ^TextBuffer) -> cstring ---
	// Buf is zero-terminated, so end() will point on the zero-terminator
	@(link_name = "ImGuiTextBuffer_end")
	text_buffer_end :: proc(self: ^TextBuffer) -> cstring ---
	@(link_name = "ImGuiTextBuffer_size")
	text_buffer_size :: proc(self: ^TextBuffer) -> i32 ---
	@(link_name = "ImGuiTextBuffer_empty")
	text_buffer_empty :: proc(self: ^TextBuffer) -> bool ---
	@(link_name = "ImGuiTextBuffer_clear")
	text_buffer_clear :: proc(self: ^TextBuffer) ---
	@(link_name = "ImGuiTextBuffer_reserve")
	text_buffer_reserve :: proc(self: ^TextBuffer, capacity: i32) ---
	@(link_name = "ImGuiTextBuffer_c_str")
	text_buffer_c_str :: proc(self: ^TextBuffer) -> cstring ---
	@(link_name = "ImGuiTextBuffer_append")
	text_buffer_append :: proc(self: ^TextBuffer, str: cstring, str_end: cstring = nil) ---
	@(link_name = "ImGuiTextBuffer_appendf")
	text_buffer_appendf :: proc(self: ^TextBuffer, fmt: cstring, #c_vararg args: ..any) ---
	// - Get***() functions find pair, never add/allocate. Pairs are sorted so a query is O(log N)
	// - Set***() functions find pair, insertion on demand if missing.
	// - Sorted insertion is costly, paid once. A typical frame shouldn't need to insert any new pair.
	@(link_name = "ImGuiStorage_Clear")
	storage_clear :: proc(self: ^Storage) ---
	@(link_name = "ImGuiStorage_GetInt")
	storage_get_int :: proc(self: ^Storage, key: ID, default_val: i32 = 0) -> i32 ---
	@(link_name = "ImGuiStorage_SetInt")
	storage_set_int :: proc(self: ^Storage, key: ID, val: i32) ---
	@(link_name = "ImGuiStorage_GetBool")
	storage_get_bool :: proc(self: ^Storage, key: ID, default_val: bool = false) -> bool ---
	@(link_name = "ImGuiStorage_SetBool")
	storage_set_bool :: proc(self: ^Storage, key: ID, val: bool) ---
	@(link_name = "ImGuiStorage_GetFloat")
	storage_get_float :: proc(self: ^Storage, key: ID, default_val: f32 = 0.0) -> f32 ---
	@(link_name = "ImGuiStorage_SetFloat")
	storage_set_float :: proc(self: ^Storage, key: ID, val: f32) ---
	// default_val is NULL
	@(link_name = "ImGuiStorage_GetVoidPtr")
	storage_get_void_ptr :: proc(self: ^Storage, key: ID) -> rawptr ---
	@(link_name = "ImGuiStorage_SetVoidPtr")
	storage_set_void_ptr :: proc(self: ^Storage, key: ID, val: rawptr) ---
	// - Get***Ref() functions finds pair, insert on demand if missing, return pointer. Useful if you intend to do Get+Set.
	// - References are only valid until a new value is added to the storage. Calling a Set***() function or a Get***Ref() function invalidates the pointer.
	// - A typical use case where this is convenient for quick hacking (e.g. add storage during a live Edit&Continue session if you can't modify existing struct)
	//      float* pvar = ImGui::GetFloatRef(key); ImGui::SliderFloat("var", pvar, 0, 100.0f); some_var += *pvar;
	@(link_name = "ImGuiStorage_GetIntRef")
	storage_get_int_ref :: proc(self: ^Storage, key: ID, default_val: i32 = 0) -> ^i32 ---
	@(link_name = "ImGuiStorage_GetBoolRef")
	storage_get_bool_ref :: proc(self: ^Storage, key: ID, default_val: bool = false) -> ^bool ---
	@(link_name = "ImGuiStorage_GetFloatRef")
	storage_get_float_ref :: proc(self: ^Storage, key: ID, default_val: f32 = 0.0) -> ^f32 ---
	@(link_name = "ImGuiStorage_GetVoidPtrRef")
	storage_get_void_ptr_ref :: proc(self: ^Storage, key: ID, default_val: rawptr = nil) -> ^rawptr ---
	// Advanced: for quicker full rebuild of a storage (instead of an incremental one), you may add all your contents and then sort once.
	@(link_name = "ImGuiStorage_BuildSortByKey")
	storage_build_sort_by_key :: proc(self: ^Storage) ---
	// Obsolete: use on your own storage if you know only integer are being stored (open/close all tree nodes)
	@(link_name = "ImGuiStorage_SetAllInt")
	storage_set_all_int :: proc(self: ^Storage, val: i32) ---
	@(link_name = "ImGuiListClipper_Begin")
	list_clipper_begin :: proc(self: ^ListClipper, items_count: i32, items_height: f32 = -1.0) ---
	// Automatically called on the last call of Step() that returns false.
	@(link_name = "ImGuiListClipper_End")
	list_clipper_end :: proc(self: ^ListClipper) ---
	// Call until it returns false. The DisplayStart/DisplayEnd fields will be set and you can process/draw those items.
	@(link_name = "ImGuiListClipper_Step")
	list_clipper_step :: proc(self: ^ListClipper) -> bool ---
	// Call IncludeItemByIndex() or IncludeItemsByIndex() *BEFORE* first call to Step() if you need a range of items to not be clipped, regardless of their visibility.
	// (Due to alignment / padding of certain items it is possible that an extra item may be included on either end of the display range).
	@(link_name = "ImGuiListClipper_IncludeItemByIndex")
	list_clipper_include_item_by_index :: proc(self: ^ListClipper, item_index: i32) ---
	// item_end is exclusive e.g. use (42, 42+1) to make item 42 never clipped.
	@(link_name = "ImGuiListClipper_IncludeItemsByIndex")
	list_clipper_include_items_by_index :: proc(self: ^ListClipper, item_begin: i32, item_end: i32) ---
	// Seek cursor toward given item. This is automatically called while stepping.
	// - The only reason to call this is: you can use ImGuiListClipper::Begin(INT_MAX) if you don't know item count ahead of time.
	// - In this case, after all steps are done, you'll want to call SeekCursorForItem(item_count).
	@(link_name = "ImGuiListClipper_SeekCursorForItem")
	list_clipper_seek_cursor_for_item :: proc(self: ^ListClipper, item_index: i32) ---
	// FIXME-OBSOLETE: May need to obsolete/cleanup those helpers.
	@(link_name = "ImColor_SetHSV")
	color_set_hsv :: proc(self: ^Color, h: f32, s: f32, v: f32, a: f32 = 1.0) ---
	@(link_name = "ImColor_HSV")
	color_hsv :: proc(h: f32, s: f32, v: f32, a: f32 = 1.0) -> Color ---
	// Apply selection requests coming from BeginMultiSelect() and EndMultiSelect() functions. It uses 'items_count' passed to BeginMultiSelect()
	@(link_name = "ImGuiSelectionBasicStorage_ApplyRequests")
	selection_basic_storage_apply_requests :: proc(self: ^SelectionBasicStorage, ms_io: ^MultiSelectIO) ---
	// Query if an item id is in selection.
	@(link_name = "ImGuiSelectionBasicStorage_Contains")
	selection_basic_storage_contains :: proc(self: ^SelectionBasicStorage, id: ID) -> bool ---
	// Clear selection
	@(link_name = "ImGuiSelectionBasicStorage_Clear")
	selection_basic_storage_clear :: proc(self: ^SelectionBasicStorage) ---
	// Swap two selections
	@(link_name = "ImGuiSelectionBasicStorage_Swap")
	selection_basic_storage_swap :: proc(self: ^SelectionBasicStorage, r: ^SelectionBasicStorage) ---
	// Add/remove an item from selection (generally done by ApplyRequests() function)
	@(link_name = "ImGuiSelectionBasicStorage_SetItemSelected")
	selection_basic_storage_set_item_selected :: proc(self: ^SelectionBasicStorage, id: ID, selected: bool) ---
	// Iterate selection with 'void* it = NULL; ImGuiId id; while (selection.GetNextSelectedItem(&it, &id)) { ... }'
	@(link_name = "ImGuiSelectionBasicStorage_GetNextSelectedItem")
	selection_basic_storage_get_next_selected_item :: proc(self: ^SelectionBasicStorage, opaque_it: ^rawptr, out_id: ^ID) -> bool ---
	// Convert index to item id based on provided adapter.
	@(link_name = "ImGuiSelectionBasicStorage_GetStorageIdFromIndex")
	selection_basic_storage_get_storage_id_from_index :: proc(self: ^SelectionBasicStorage, idx: i32) -> ID ---
	// Apply selection requests by using AdapterSetItemSelected() calls
	@(link_name = "ImGuiSelectionExternalStorage_ApplyRequests")
	selection_external_storage_apply_requests :: proc(self: ^SelectionExternalStorage, ms_io: ^MultiSelectIO) ---
	// Since 1.83: returns ImTextureID associated with this draw call. Warning: DO NOT assume this is always same as 'TextureId' (we will change this function for an upcoming feature)
	@(link_name = "ImDrawCmd_GetTexID")
	draw_cmd_get_tex_id :: proc(self: ^DrawCmd) -> TextureID ---
	// Do not clear Channels[] so our allocations are reused next frame
	@(link_name = "ImDrawListSplitter_Clear")
	draw_list_splitter_clear :: proc(self: ^DrawListSplitter) ---
	@(link_name = "ImDrawListSplitter_ClearFreeMemory")
	draw_list_splitter_clear_free_memory :: proc(self: ^DrawListSplitter) ---
	@(link_name = "ImDrawListSplitter_Split")
	draw_list_splitter_split :: proc(self: ^DrawListSplitter, draw_list: ^DrawList, count: i32) ---
	@(link_name = "ImDrawListSplitter_Merge")
	draw_list_splitter_merge :: proc(self: ^DrawListSplitter, draw_list: ^DrawList) ---
	@(link_name = "ImDrawListSplitter_SetCurrentChannel")
	draw_list_splitter_set_current_channel :: proc(self: ^DrawListSplitter, draw_list: ^DrawList, channel_idx: i32) ---
	// Render-level scissoring. This is passed down to your render function but not used for CPU-side coarse clipping. Prefer using higher-level ImGui::PushClipRect() to affect logic (hit-testing and widget culling)
	@(link_name = "ImDrawList_PushClipRect")
	draw_list_push_clip_rect :: proc(self: ^DrawList, clip_rect_min: Vec2, clip_rect_max: Vec2, intersect_with_current_clip_rect: bool = false) ---
	@(link_name = "ImDrawList_PushClipRectFullScreen")
	draw_list_push_clip_rect_full_screen :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList_PopClipRect")
	draw_list_pop_clip_rect :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList_PushTextureID")
	draw_list_push_texture_id :: proc(self: ^DrawList, texture_id: TextureID) ---
	@(link_name = "ImDrawList_PopTextureID")
	draw_list_pop_texture_id :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList_GetClipRectMin")
	draw_list_get_clip_rect_min :: proc(self: ^DrawList) -> Vec2 ---
	@(link_name = "ImDrawList_GetClipRectMax")
	draw_list_get_clip_rect_max :: proc(self: ^DrawList) -> Vec2 ---
	// Primitives
	// - Filled shapes must always use clockwise winding order. The anti-aliasing fringe depends on it. Counter-clockwise shapes will have "inward" anti-aliasing.
	// - For rectangular primitives, "p_min" and "p_max" represent the upper-left and lower-right corners.
	// - For circle primitives, use "num_segments == 0" to automatically calculate tessellation (preferred).
	//   In older versions (until Dear ImGui 1.77) the AddCircle functions defaulted to num_segments == 12.
	//   In future versions we will use textures to provide cheaper and higher-quality circles.
	//   Use AddNgon() and AddNgonFilled() functions if you need to guarantee a specific number of sides.
	@(link_name = "ImDrawList_AddLine")
	draw_list_add_line :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, col: u32, thickness: f32 = 1.0) ---
	// a: upper-left, b: lower-right (== upper-left + size)
	@(link_name = "ImDrawList_AddRect")
	draw_list_add_rect :: proc(self: ^DrawList, p_min: Vec2, p_max: Vec2, col: u32, rounding: f32 = 0.0, flags: DrawFlags = {}, thickness: f32 = 1.0) ---
	// a: upper-left, b: lower-right (== upper-left + size)
	@(link_name = "ImDrawList_AddRectFilled")
	draw_list_add_rect_filled :: proc(self: ^DrawList, p_min: Vec2, p_max: Vec2, col: u32, rounding: f32 = 0.0, flags: DrawFlags = {}) ---
	@(link_name = "ImDrawList_AddRectFilledMultiColor")
	draw_list_add_rect_filled_multi_color :: proc(self: ^DrawList, p_min: Vec2, p_max: Vec2, col_upr_left: u32, col_upr_right: u32, col_bot_right: u32, col_bot_left: u32) ---
	@(link_name = "ImDrawList_AddQuad")
	draw_list_add_quad :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, col: u32, thickness: f32 = 1.0) ---
	@(link_name = "ImDrawList_AddQuadFilled")
	draw_list_add_quad_filled :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, col: u32) ---
	@(link_name = "ImDrawList_AddTriangle")
	draw_list_add_triangle :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, p3: Vec2, col: u32, thickness: f32 = 1.0) ---
	@(link_name = "ImDrawList_AddTriangleFilled")
	draw_list_add_triangle_filled :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, p3: Vec2, col: u32) ---
	@(link_name = "ImDrawList_AddCircle")
	draw_list_add_circle :: proc(self: ^DrawList, center: Vec2, radius: f32, col: u32, num_segments: i32 = 0, thickness: f32 = 1.0) ---
	@(link_name = "ImDrawList_AddCircleFilled")
	draw_list_add_circle_filled :: proc(self: ^DrawList, center: Vec2, radius: f32, col: u32, num_segments: i32 = 0) ---
	@(link_name = "ImDrawList_AddNgon")
	draw_list_add_ngon :: proc(self: ^DrawList, center: Vec2, radius: f32, col: u32, num_segments: i32, thickness: f32 = 1.0) ---
	@(link_name = "ImDrawList_AddNgonFilled")
	draw_list_add_ngon_filled :: proc(self: ^DrawList, center: Vec2, radius: f32, col: u32, num_segments: i32) ---
	@(link_name = "ImDrawList_AddEllipse")
	draw_list_add_ellipse :: proc(self: ^DrawList, center: Vec2, radius: Vec2, col: u32, rot: f32 = 0.0, num_segments: i32 = 0, thickness: f32 = 1.0) ---
	@(link_name = "ImDrawList_AddEllipseFilled")
	draw_list_add_ellipse_filled :: proc(self: ^DrawList, center: Vec2, radius: Vec2, col: u32, rot: f32 = 0.0, num_segments: i32 = 0) ---
	@(link_name = "ImDrawList_AddText")
	draw_list_add_text :: proc(self: ^DrawList, pos: Vec2, col: u32, text_begin: cstring, text_end: cstring = nil) ---
	@(link_name = "ImDrawList_AddTextImFontPtr")
	draw_list_add_text_font_ptr :: proc(self: ^DrawList, font: ^Font, font_size: f32, pos: Vec2, col: u32, text_begin: cstring, text_end: cstring = nil, wrap_width: f32 = 0.0, cpu_fine_clip_rect: ^Vec4 = nil) ---
	// Cubic Bezier (4 control points)
	@(link_name = "ImDrawList_AddBezierCubic")
	draw_list_add_bezier_cubic :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, col: u32, thickness: f32, num_segments: i32 = 0) ---
	// Quadratic Bezier (3 control points)
	@(link_name = "ImDrawList_AddBezierQuadratic")
	draw_list_add_bezier_quadratic :: proc(self: ^DrawList, p1: Vec2, p2: Vec2, p3: Vec2, col: u32, thickness: f32, num_segments: i32 = 0) ---
	// General polygon
	// - Only simple polygons are supported by filling functions (no self-intersections, no holes).
	// - Concave polygon fill is more expensive than convex one: it has O(N^2) complexity. Provided as a convenience fo user but not used by main library.
	@(link_name = "ImDrawList_AddPolyline")
	draw_list_add_polyline :: proc(self: ^DrawList, points: ^Vec2, num_points: i32, col: u32, flags: DrawFlags, thickness: f32) ---
	@(link_name = "ImDrawList_AddConvexPolyFilled")
	draw_list_add_convex_poly_filled :: proc(self: ^DrawList, points: ^Vec2, num_points: i32, col: u32) ---
	@(link_name = "ImDrawList_AddConcavePolyFilled")
	draw_list_add_concave_poly_filled :: proc(self: ^DrawList, points: ^Vec2, num_points: i32, col: u32) ---
	// Image primitives
	// - Read FAQ to understand what ImTextureID is.
	// - "p_min" and "p_max" represent the upper-left and lower-right corners of the rectangle.
	// - "uv_min" and "uv_max" represent the normalized texture coordinates to use for those corners. Using (0,0)->(1,1) texture coordinates will generally display the entire texture.
	@(link_name = "ImDrawList_AddImage")
	im_draw_list_add_image :: proc(self: ^DrawList, user_texture_id: TextureID, p_min: Vec2, p_max: Vec2, uv_min: Vec2 = Vec2{0, 0}, uv_max: Vec2 = Vec2{1, 1}, col: u32 = 0xff_ff_ff_ff) ---
	@(link_name = "ImDrawList_AddImageQuad")
	im_draw_list_add_image_quad :: proc(self: ^DrawList, user_texture_id: TextureID, p1: Vec2, p2: Vec2, p3: Vec2, p4: Vec2, uv1: Vec2 = Vec2{0, 0}, uv2: Vec2 = Vec2{1, 0}, uv3: Vec2 = Vec2{1, 1}, uv4: Vec2 = Vec2{0, 1}, col: u32 = 0xff_ff_ff_ff) ---
	@(link_name = "ImDrawList_AddImageRounded")
	im_draw_list_add_image_rounded :: proc(self: ^DrawList, user_texture_id: TextureID, p_min: Vec2, p_max: Vec2, uv_min: Vec2, uv_max: Vec2, col: u32, rounding: f32, flags: DrawFlags = {}) ---
	// Stateful path API, add points then finish with PathFillConvex() or PathStroke()
	// - Important: filled shapes must always use clockwise winding order! The anti-aliasing fringe depends on it. Counter-clockwise shapes will have "inward" anti-aliasing.
	//   so e.g. 'PathArcTo(center, radius, PI * -0.5f, PI)' is ok, whereas 'PathArcTo(center, radius, PI, PI * -0.5f)' won't have correct anti-aliasing when followed by PathFillConvex().
	@(link_name = "ImDrawList_PathClear")
	draw_list_path_clear :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList_PathLineTo")
	draw_list_path_line_to :: proc(self: ^DrawList, pos: Vec2) ---
	@(link_name = "ImDrawList_PathLineToMergeDuplicate")
	draw_list_path_line_to_merge_duplicate :: proc(self: ^DrawList, pos: Vec2) ---
	@(link_name = "ImDrawList_PathFillConvex")
	draw_list_path_fill_convex :: proc(self: ^DrawList, col: u32) ---
	@(link_name = "ImDrawList_PathFillConcave")
	draw_list_path_fill_concave :: proc(self: ^DrawList, col: u32) ---
	@(link_name = "ImDrawList_PathStroke")
	draw_list_path_stroke :: proc(self: ^DrawList, col: u32, flags: DrawFlags = {}, thickness: f32 = 1.0) ---
	@(link_name = "ImDrawList_PathArcTo")
	draw_list_path_arc_to :: proc(self: ^DrawList, center: Vec2, radius: f32, a_min: f32, a_max: f32, num_segments: i32 = 0) ---
	// Use precomputed angles for a 12 steps circle
	@(link_name = "ImDrawList_PathArcToFast")
	draw_list_path_arc_to_fast :: proc(self: ^DrawList, center: Vec2, radius: f32, a_min_of_12: i32, a_max_of_12: i32) ---
	// Ellipse
	@(link_name = "ImDrawList_PathEllipticalArcTo")
	draw_list_path_elliptical_arc_to :: proc(self: ^DrawList, center: Vec2, radius: Vec2, rot: f32, a_min: f32, a_max: f32, num_segments: i32 = 0) ---
	// Cubic Bezier (4 control points)
	@(link_name = "ImDrawList_PathBezierCubicCurveTo")
	draw_list_path_bezier_cubic_curve_to :: proc(self: ^DrawList, p2: Vec2, p3: Vec2, p4: Vec2, num_segments: i32 = 0) ---
	// Quadratic Bezier (3 control points)
	@(link_name = "ImDrawList_PathBezierQuadraticCurveTo")
	draw_list_path_bezier_quadratic_curve_to :: proc(self: ^DrawList, p2: Vec2, p3: Vec2, num_segments: i32 = 0) ---
	@(link_name = "ImDrawList_PathRect")
	draw_list_path_rect :: proc(self: ^DrawList, rect_min: Vec2, rect_max: Vec2, rounding: f32 = 0.0, flags: DrawFlags = {}) ---
	// Advanced: Draw Callbacks
	// - May be used to alter render state (change sampler, blending, current shader). May be used to emit custom rendering commands (difficult to do correctly, but possible).
	// - Use special ImDrawCallback_ResetRenderState callback to instruct backend to reset its render state to the default.
	// - Your rendering loop must check for 'UserCallback' in ImDrawCmd and call the function instead of rendering triangles. All standard backends are honoring this.
	// - For some backends, the callback may access selected render-states exposed by the backend in a ImGui_ImplXXXX_RenderState structure pointed to by platform_io.Renderer_RenderState.
	// - IMPORTANT: please be mindful of the different level of indirection between using size==0 (copying argument) and using size>0 (copying pointed data into a buffer).
	//   - If userdata_size == 0: we copy/store the 'userdata' argument as-is. It will be available unmodified in ImDrawCmd::UserCallbackData during render.
	//   - If userdata_size > 0,  we copy/store 'userdata_size' bytes pointed to by 'userdata'. We store them in a buffer stored inside the drawlist. ImDrawCmd::UserCallbackData will point inside that buffer so you have to retrieve data from there. Your callback may need to use ImDrawCmd::UserCallbackDataSize if you expect dynamically-sized data.
	//   - Support for userdata_size > 0 was added in v1.91.4, October 2024. So earlier code always only allowed to copy/store a simple void*.
	@(link_name = "ImDrawList_AddCallback")
	draw_list_add_callback :: proc(self: ^DrawList, callback: DrawCallback, userdata: rawptr, userdata_size: uint = {}) ---
	// Advanced: Miscellaneous
	// This is useful if you need to forcefully create a new draw call (to allow for dependent rendering / blending). Otherwise primitives are merged into the same draw-call as much as possible
	@(link_name = "ImDrawList_AddDrawCmd")
	draw_list_add_draw_cmd :: proc(self: ^DrawList) ---
	// Create a clone of the CmdBuffer/IdxBuffer/VtxBuffer.
	@(link_name = "ImDrawList_CloneOutput")
	draw_list_clone_output :: proc(self: ^DrawList) -> ^DrawList ---
	// Advanced: Channels
	// - Use to split render into layers. By switching channels to can render out-of-order (e.g. submit FG primitives before BG primitives)
	// - Use to minimize draw calls (e.g. if going back-and-forth between multiple clipping rectangles, prefer to append into separate channels then merge at the end)
	// - This API shouldn't have been in ImDrawList in the first place!
	//   Prefer using your own persistent instance of ImDrawListSplitter as you can stack them.
	//   Using the ImDrawList::ChannelsXXXX you cannot stack a split over another.
	@(link_name = "ImDrawList_ChannelsSplit")
	draw_list_channels_split :: proc(self: ^DrawList, count: i32) ---
	@(link_name = "ImDrawList_ChannelsMerge")
	draw_list_channels_merge :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList_ChannelsSetCurrent")
	draw_list_channels_set_current :: proc(self: ^DrawList, n: i32) ---
	// Advanced: Primitives allocations
	// - We render triangles (three vertices)
	// - All primitives needs to be reserved via PrimReserve() beforehand.
	@(link_name = "ImDrawList_PrimReserve")
	draw_list_prim_reserve :: proc(self: ^DrawList, idx_count: i32, vtx_count: i32) ---
	@(link_name = "ImDrawList_PrimUnreserve")
	draw_list_prim_unreserve :: proc(self: ^DrawList, idx_count: i32, vtx_count: i32) ---
	// Axis aligned rectangle (composed of two triangles)
	@(link_name = "ImDrawList_PrimRect")
	draw_list_prim_rect :: proc(self: ^DrawList, a: Vec2, b: Vec2, col: u32) ---
	@(link_name = "ImDrawList_PrimRectUV")
	draw_list_prim_rect_uv :: proc(self: ^DrawList, a: Vec2, b: Vec2, uv_a: Vec2, uv_b: Vec2, col: u32) ---
	@(link_name = "ImDrawList_PrimQuadUV")
	draw_list_prim_quad_uv :: proc(self: ^DrawList, a: Vec2, b: Vec2, c: Vec2, d: Vec2, uv_a: Vec2, uv_b: Vec2, uv_c: Vec2, uv_d: Vec2, col: u32) ---
	@(link_name = "ImDrawList_PrimWriteVtx")
	draw_list_prim_write_vtx :: proc(self: ^DrawList, pos: Vec2, uv: Vec2, col: u32) ---
	@(link_name = "ImDrawList_PrimWriteIdx")
	draw_list_prim_write_idx :: proc(self: ^DrawList, idx: DrawIdx) ---
	// Write vertex with unique index
	@(link_name = "ImDrawList_PrimVtx")
	draw_list_prim_vtx :: proc(self: ^DrawList, pos: Vec2, uv: Vec2, col: u32) ---
	// [Internal helpers]
	@(link_name = "ImDrawList__ResetForNewFrame")
	draw_list_reset_for_new_frame :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__ClearFreeMemory")
	draw_list_clear_free_memory :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__PopUnusedDrawCmd")
	draw_list_pop_unused_draw_cmd :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__TryMergeDrawCmds")
	draw_list_try_merge_draw_cmds :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__OnChangedClipRect")
	draw_list_on_changed_clip_rect :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__OnChangedTextureID")
	draw_list_on_changed_texture_id :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__OnChangedVtxOffset")
	draw_list_on_changed_vtx_offset :: proc(self: ^DrawList) ---
	@(link_name = "ImDrawList__SetTextureID")
	draw_list_set_texture_id :: proc(self: ^DrawList, texture_id: TextureID) ---
	@(link_name = "ImDrawList__CalcCircleAutoSegmentCount")
	draw_list_calc_circle_auto_segment_count :: proc(self: ^DrawList, radius: f32) -> i32 ---
	@(link_name = "ImDrawList__PathArcToFastEx")
	draw_list_path_arc_to_fast_ex :: proc(self: ^DrawList, center: Vec2, radius: f32, a_min_sample: i32, a_max_sample: i32, a_step: i32) ---
	@(link_name = "ImDrawList__PathArcToN")
	draw_list_path_arc_to_n :: proc(self: ^DrawList, center: Vec2, radius: f32, a_min: f32, a_max: f32, num_segments: i32) ---
	@(link_name = "ImDrawData_Clear")
	draw_data_clear :: proc(self: ^DrawData) ---
	// Helper to add an external draw list into an existing ImDrawData.
	@(link_name = "ImDrawData_AddDrawList")
	draw_data_add_draw_list :: proc(self: ^DrawData, draw_list: ^DrawList) ---
	// Helper to convert all buffers from indexed to non-indexed, in case you cannot render indexed. Note: this is slow and most likely a waste of resources. Always prefer indexed rendering!
	@(link_name = "ImDrawData_DeIndexAllBuffers")
	draw_data_de_index_all_buffers :: proc(self: ^DrawData) ---
	// Helper to scale the ClipRect field of each ImDrawCmd. Use if your final output buffer is at a different scale than Dear ImGui expects, or if there is a difference between your window resolution and framebuffer resolution.
	@(link_name = "ImDrawData_ScaleClipRects")
	draw_data_scale_clip_rects :: proc(self: ^DrawData, fb_scale: Vec2) ---
	@(link_name = "ImFontGlyphRangesBuilder_Clear")
	font_glyph_ranges_builder_clear :: proc(self: ^FontGlyphRangesBuilder) ---
	// Get bit n in the array
	@(link_name = "ImFontGlyphRangesBuilder_GetBit")
	font_glyph_ranges_builder_get_bit :: proc(self: ^FontGlyphRangesBuilder, n: uint) -> bool ---
	// Set bit n in the array
	@(link_name = "ImFontGlyphRangesBuilder_SetBit")
	font_glyph_ranges_builder_set_bit :: proc(self: ^FontGlyphRangesBuilder, n: uint) ---
	// Add character
	@(link_name = "ImFontGlyphRangesBuilder_AddChar")
	font_glyph_ranges_builder_add_char :: proc(self: ^FontGlyphRangesBuilder, c: Wchar) ---
	// Add string (each character of the UTF-8 string are added)
	@(link_name = "ImFontGlyphRangesBuilder_AddText")
	font_glyph_ranges_builder_add_text :: proc(self: ^FontGlyphRangesBuilder, text: cstring, text_end: cstring = nil) ---
	// Add ranges, e.g. builder.AddRanges(ImFontAtlas::GetGlyphRangesDefault()) to force add all of ASCII/Latin+Ext
	@(link_name = "ImFontGlyphRangesBuilder_AddRanges")
	font_glyph_ranges_builder_add_ranges :: proc(self: ^FontGlyphRangesBuilder, ranges: cstring) ---
	// Output new ranges (ImVector_Construct()/ImVector_Destruct() can be used to safely construct out_ranges)
	@(link_name = "ImFontGlyphRangesBuilder_BuildRanges")
	font_glyph_ranges_builder_build_ranges :: proc(self: ^FontGlyphRangesBuilder, out_ranges: cstring) ---
	@(link_name = "ImFontAtlasCustomRect_IsPacked")
	font_atlas_custom_rect_is_packed :: proc(self: ^FontAtlasCustomRect) -> bool ---
	@(link_name = "ImFontAtlas_AddFont")
	font_atlas_add_font :: proc(self: ^FontAtlas, font_cfg: ^FontConfig) -> ^Font ---
	@(link_name = "ImFontAtlas_AddFontDefault")
	font_atlas_add_font_default :: proc(self: ^FontAtlas, font_cfg: ^FontConfig = nil) -> ^Font ---
	@(link_name = "ImFontAtlas_AddFontFromFileTTF")
	font_atlas_add_font_from_file_ttf :: proc(self: ^FontAtlas, filename: cstring, size_pixels: f32, font_cfg: ^FontConfig = nil, glyph_ranges: cstring = nil) -> ^Font ---
	// Note: Transfer ownership of 'ttf_data' to ImFontAtlas! Will be deleted after destruction of the atlas. Set font_cfg->FontDataOwnedByAtlas=false to keep ownership of your data and it won't be freed.
	@(link_name = "ImFontAtlas_AddFontFromMemoryTTF")
	font_atlas_add_font_from_memory_ttf :: proc(self: ^FontAtlas, font_data: rawptr, font_data_size: i32, size_pixels: f32, font_cfg: ^FontConfig = nil, glyph_ranges: cstring = nil) -> ^Font ---
	// 'compressed_font_data' still owned by caller. Compress with binary_to_compressed_c.cpp.
	@(link_name = "ImFontAtlas_AddFontFromMemoryCompressedTTF")
	font_atlas_add_font_from_memory_compressed_ttf :: proc(self: ^FontAtlas, compressed_font_data: rawptr, compressed_font_data_size: i32, size_pixels: f32, font_cfg: ^FontConfig = nil, glyph_ranges: cstring = nil) -> ^Font ---
	// 'compressed_font_data_base85' still owned by caller. Compress with binary_to_compressed_c.cpp with -base85 parameter.
	@(link_name = "ImFontAtlas_AddFontFromMemoryCompressedBase85TTF")
	font_atlas_add_font_from_memory_compressed_base85ttf :: proc(self: ^FontAtlas, compressed_font_data_base85: cstring, size_pixels: f32, font_cfg: ^FontConfig = nil, glyph_ranges: cstring = nil) -> ^Font ---
	// Clear input data (all ImFontConfig structures including sizes, TTF data, glyph ranges, etc.) = all the data used to build the texture and fonts.
	@(link_name = "ImFontAtlas_ClearInputData")
	font_atlas_clear_input_data :: proc(self: ^FontAtlas) ---
	// Clear output texture data (CPU side). Saves RAM once the texture has been copied to graphics memory.
	@(link_name = "ImFontAtlas_ClearTexData")
	font_atlas_clear_tex_data :: proc(self: ^FontAtlas) ---
	// Clear output font data (glyphs storage, UV coordinates).
	@(link_name = "ImFontAtlas_ClearFonts")
	font_atlas_clear_fonts :: proc(self: ^FontAtlas) ---
	// Clear all input and output.
	@(link_name = "ImFontAtlas_Clear")
	font_atlas_clear :: proc(self: ^FontAtlas) ---
	// Build atlas, retrieve pixel data.
	// User is in charge of copying the pixels into graphics memory (e.g. create a texture with your engine). Then store your texture handle with SetTexID().
	// The pitch is always = Width * BytesPerPixels (1 or 4)
	// Building in RGBA32 format is provided for convenience and compatibility, but note that unless you manually manipulate or copy color data into
	// the texture (e.g. when using the AddCustomRect*** api), then the RGB pixels emitted will always be white (~75% of memory/bandwidth waste.
	// Build pixels data. This is called automatically for you by the GetTexData*** functions.
	@(link_name = "ImFontAtlas_Build")
	font_atlas_build :: proc(self: ^FontAtlas) -> bool ---
	// 1 byte per-pixel
	@(link_name = "ImFontAtlas_GetTexDataAsAlpha8")
	font_atlas_get_tex_data_as_alpha8 :: proc(self: ^FontAtlas, out_pixels: ^^u8, out_width: ^i32, out_height: ^i32, out_bytes_per_pixel: ^i32 = nil) ---
	// 4 bytes-per-pixel
	@(link_name = "ImFontAtlas_GetTexDataAsRGBA32")
	font_atlas_get_tex_data_as_rgba32 :: proc(self: ^FontAtlas, out_pixels: ^^u8, out_width: ^i32, out_height: ^i32, out_bytes_per_pixel: ^i32 = nil) ---
	// Bit ambiguous: used to detect when user didn't build texture but effectively we should check TexID != 0 except that would be backend dependent...
	@(link_name = "ImFontAtlas_IsBuilt")
	font_atlas_is_built :: proc(self: ^FontAtlas) -> bool ---
	@(link_name = "ImFontAtlas_SetTexID")
	font_atlas_set_tex_id :: proc(self: ^FontAtlas, id: TextureID) ---
	// Helpers to retrieve list of common Unicode ranges (2 value per range, values are inclusive, zero-terminated list)
	// NB: Make sure that your string are UTF-8 and NOT in your local code page.
	// Read https://github.com/ocornut/imgui/blob/master/docs/FONTS.md/#about-utf-8-encoding for details.
	// NB: Consider using ImFontGlyphRangesBuilder to build glyph ranges from textual data.
	// Basic Latin, Extended Latin
	@(link_name = "ImFontAtlas_GetGlyphRangesDefault")
	font_atlas_get_glyph_ranges_default :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Greek and Coptic
	@(link_name = "ImFontAtlas_GetGlyphRangesGreek")
	font_atlas_get_glyph_ranges_greek :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Korean characters
	@(link_name = "ImFontAtlas_GetGlyphRangesKorean")
	font_atlas_get_glyph_ranges_korean :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Hiragana, Katakana, Half-Width, Selection of 2999 Ideographs
	@(link_name = "ImFontAtlas_GetGlyphRangesJapanese")
	font_atlas_get_glyph_ranges_japanese :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Half-Width + Japanese Hiragana/Katakana + full set of about 21000 CJK Unified Ideographs
	@(link_name = "ImFontAtlas_GetGlyphRangesChineseFull")
	font_atlas_get_glyph_ranges_chinese_full :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Half-Width + Japanese Hiragana/Katakana + set of 2500 CJK Unified Ideographs for common simplified Chinese
	@(link_name = "ImFontAtlas_GetGlyphRangesChineseSimplifiedCommon")
	font_atlas_get_glyph_ranges_chinese_simplified_common :: proc(self: ^FontAtlas) -> cstring ---
	// Default + about 400 Cyrillic characters
	@(link_name = "ImFontAtlas_GetGlyphRangesCyrillic")
	font_atlas_get_glyph_ranges_cyrillic :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Thai characters
	@(link_name = "ImFontAtlas_GetGlyphRangesThai")
	font_atlas_get_glyph_ranges_thai :: proc(self: ^FontAtlas) -> cstring ---
	// Default + Vietnamese characters
	@(link_name = "ImFontAtlas_GetGlyphRangesVietnamese")
	font_atlas_get_glyph_ranges_vietnamese :: proc(self: ^FontAtlas) -> cstring ---
	// You can request arbitrary rectangles to be packed into the atlas, for your own purposes.
	// - After calling Build(), you can query the rectangle position and render your pixels.
	// - If you render colored output, set 'atlas->TexPixelsUseColors = true' as this may help some backends decide of preferred texture format.
	// - You can also request your rectangles to be mapped as font glyph (given a font + Unicode point),
	//   so you can render e.g. custom colorful icons and use them as regular glyphs.
	// - Read docs/FONTS.md for more details about using colorful icons.
	// - Note: this API may be redesigned later in order to support multi-monitor varying DPI settings.
	@(link_name = "ImFontAtlas_AddCustomRectRegular")
	font_atlas_add_custom_rect_regular :: proc(self: ^FontAtlas, width: i32, height: i32) -> i32 ---
	@(link_name = "ImFontAtlas_AddCustomRectFontGlyph")
	font_atlas_add_custom_rect_font_glyph :: proc(self: ^FontAtlas, font: ^Font, id: Wchar, width: i32, height: i32, advance_x: f32, offset: Vec2 = Vec2{0, 0}) -> i32 ---
	@(link_name = "ImFontAtlas_GetCustomRectByIndex")
	font_atlas_get_custom_rect_by_index :: proc(self: ^FontAtlas, index: i32) -> ^FontAtlasCustomRect ---
	// [Internal]
	@(link_name = "ImFontAtlas_CalcCustomRectUV")
	font_atlas_calc_custom_rect_uv :: proc(self: ^FontAtlas, rect: ^FontAtlasCustomRect, out_uv_min: ^Vec2, out_uv_max: ^Vec2) ---
	@(link_name = "ImFontAtlas_GetMouseCursorTexData")
	font_atlas_get_mouse_cursor_tex_data :: proc(self: ^FontAtlas, cursor: MouseCursor, out_offset: ^Vec2, out_size: ^Vec2, out_uv_border: ^[2]Vec2, out_uv_fill: ^[2]Vec2) -> bool ---
	@(link_name = "ImFont_FindGlyph")
	font_find_glyph :: proc(self: ^Font, c: Wchar) -> ^FontGlyph ---
	@(link_name = "ImFont_FindGlyphNoFallback")
	font_find_glyph_no_fallback :: proc(self: ^Font, c: Wchar) -> ^FontGlyph ---
	@(link_name = "ImFont_GetCharAdvance")
	font_get_char_advance :: proc(self: ^Font, c: Wchar) -> f32 ---
	@(link_name = "ImFont_IsLoaded")
	font_is_loaded :: proc(self: ^Font) -> bool ---
	@(link_name = "ImFont_GetDebugName")
	font_get_debug_name :: proc(self: ^Font) -> cstring ---
	// 'max_width' stops rendering after a certain width (could be turned into a 2d size). FLT_MAX to disable.
	// 'wrap_width' enable automatic word-wrapping across multiple lines to fit into given width. 0.0f to disable.
	// utf8
	@(link_name = "ImFont_CalcTextSizeA")
	font_calc_text_size_a :: proc(self: ^Font, size: f32, max_width: f32, wrap_width: f32, text_begin: cstring, text_end: cstring = nil, remaining: cstring = nil) -> Vec2 ---
	@(link_name = "ImFont_CalcWordWrapPositionA")
	font_calc_word_wrap_position_a :: proc(self: ^Font, scale: f32, text: cstring, text_end: cstring, wrap_width: f32) -> cstring ---
	@(link_name = "ImFont_RenderChar")
	font_render_char :: proc(self: ^Font, draw_list: ^DrawList, size: f32, pos: Vec2, col: u32, c: Wchar) ---
	@(link_name = "ImFont_RenderText")
	font_render_text :: proc(self: ^Font, draw_list: ^DrawList, size: f32, pos: Vec2, col: u32, clip_rect: Vec4, text_begin: cstring, text_end: cstring, wrap_width: f32 = 0.0, cpu_fine_clip: bool = false) ---
	// [Internal] Don't use!
	@(link_name = "ImFont_BuildLookupTable")
	font_build_lookup_table :: proc(self: ^Font) ---
	@(link_name = "ImFont_ClearOutputData")
	font_clear_output_data :: proc(self: ^Font) ---
	@(link_name = "ImFont_GrowIndex")
	font_grow_index :: proc(self: ^Font, new_size: i32) ---
	@(link_name = "ImFont_AddGlyph")
	font_add_glyph :: proc(self: ^Font, src_cfg: ^FontConfig, c: Wchar, x0: f32, y0: f32, x1: f32, y1: f32, u0: f32, v0: f32, u1: f32, v1: f32, advance_x: f32) ---
	// Makes 'dst' character/glyph points to 'src' character/glyph. Currently needs to be called AFTER fonts have been built.
	@(link_name = "ImFont_AddRemapChar")
	font_add_remap_char :: proc(self: ^Font, dst: Wchar, src: Wchar, overwrite_dst: bool = true) ---
	@(link_name = "ImFont_SetGlyphVisible")
	font_set_glyph_visible :: proc(self: ^Font, c: Wchar, visible: bool) ---
	@(link_name = "ImFont_IsGlyphRangeUnused")
	font_is_glyph_range_unused :: proc(self: ^Font, c_begin: u32, c_last: u32) -> bool ---
	// Helpers
	@(link_name = "ImGuiViewport_GetCenter")
	viewport_get_center :: proc(self: ^Viewport) -> Vec2 ---
	@(link_name = "ImGuiViewport_GetWorkCenter")
	viewport_get_work_center :: proc(self: ^Viewport) -> Vec2 ---
}
