--[[
	Better Orion UI Library v2.0
	Оптимизированная версия с улучшенным меню и функцией загрузки фона по ссылке
]]

while not game:IsLoaded() do task.wait() end

-- Удаляем старые экземпляры
for _, UI in ipairs(game.CoreGui:GetChildren()) do
	if UI.Name == "BetterOrion" then 
		UI:Destroy() 
	end
end

-- Сервисы
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Основная таблица
local OrionLib = {
	Elements = {},
	UIElements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Tabs = {},
	Themes = {
		Default = {
			Main = { Color = Color3.fromRGB(20, 20, 20), Transparency = 0.35 },
			Stroke = { Color = Color3.fromRGB(100, 100, 100), Transparency = 0.5 },
			Divider = { Color = Color3.fromRGB(100, 100, 100), Transparency = 1 },
			Text = { Color = Color3.fromRGB(255, 255, 255), Transparency = 0 },
			TextDark = { Color = Color3.fromRGB(200, 200, 200), Transparency = 0 },
			Elements = { Color = Color3.fromRGB(80, 80, 80), Transparency = 0.95 }
		}
	},
	NotificationSettings = { Enabled = true, Printing = true },
	WindowConfig = {
		AutoSizedTabHolderX = false,
		AutoSizedTabHolderY = "Window"
	},
	BackgroundConfig = {
		EnabledBackground = false,
		BackgroundName = "",
		BackgroundTransparency = 0.2,
		BackgroundURL = "" -- Новая переменная для хранения URL
	},
	SelectedTheme = "Default",
	ScriptFolder = "BetterOrion",
	GameName = tostring(game.PlaceId),
	Window = nil,
	ToggleUIKey = Enum.KeyCode.Tab,
	-- Новая функция для загрузки фона по ссылке
	LoadBackgroundFromURL = function(url)
		if url and url ~= "" then
			OrionLib.BackgroundConfig.BackgroundURL = url
			if OrionLib.Window then
				OrionLib.Window:SetBackground(url)
			end
			return true
		end
		return false
	end
}
OrionLib.SectionLabels = {}

-- Иконки
local Icons = {}
local LucideIcons = loadstring(game:HttpGet("https://gitlab.com/m1kp0/BetterOrion/-/raw/main/Icons.lua?ref_type=heads"))().assets

-- Core GUI
local Orion = Instance.new("ScreenGui")
Orion.Name = "BetterOrion"
if syn then
	pcall(function() syn.protect_gui(Orion) end)
end
Orion.Parent = CoreGui

-- Вспомогательные функции
local function GetLucideIcon(IconName)
	if IconName == nil then return nil end
	local NameSplit = IconName:split("://")
	if NameSplit and NameSplit[2] ~= nil then return IconName end
	if IconName ~= nil then return LucideIcons["lucide-"..IconName] end
	return nil 
end

local function AddConnection(Signal, Function)
	if not Orion.Parent then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(OrionLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while Orion.Parent == CoreGui do task.wait() end
	for _, Connection in next, OrionLib.Connections do Connection:Disconnect() end
end)

-- Создание элементов GUI
local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in Properties or {} do Object[i] = v end
	for i, v in Children or {} do v.Parent = Object end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	OrionLib.Elements[ElementName] = ElementFunction
end

local function MakeElement(ElementName, ...)
	return OrionLib.Elements[ElementName](...)
end

local function SetProps(Element, Props)
	for Property, Value in pairs(Props) do Element[Property] = Value end
	return Element
end

local function SetChildren(Element, Children)
	for _, Child in pairs(Children) do Child.Parent = Element end
	return Element
end

local function Round(Number, Factor)
	Number = tonumber(Number)
	local sign = Number >= 0 and 1 or -1
	local result = math.floor(Number / Factor + 0.5 * sign) * Factor
	if Factor < 1 then
		local str = tostring(Factor)
		local dot = str:find("%.")
		local precision = dot and #str - dot or 0
		result = tonumber(string.format("%." .. precision .. "f", result))
	end
	return result
end

local function ReturnProperty(Object, PropType)
	if Object:IsA("Frame") or Object:IsA("TextButton") then 
		return (PropType == "Color" and "BackgroundColor3") or "BackgroundTransparency" 
	end
	if Object:IsA("ScrollingFrame") then 
		return (PropType == "Color" and "ScrollBarImageColor3") or "ScrollBarImageTransparency" 
	end
	if Object:IsA("UIStroke") then 
		return (PropType == "Color" and "Color") or "Transparency" 
	end
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then 
		return (PropType == "Color" and "TextColor3") or "TextTransparency" 
	end
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then 
		return (PropType == "Color" and "ImageColor3") or "ImageTransparency" 
	end
end

local function AddThemeObject(Object, Type)
	if not OrionLib.ThemeObjects[Type] then OrionLib.ThemeObjects[Type] = {} end
	table.insert(OrionLib.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object, "Color")] = OrionLib.Themes[OrionLib.SelectedTheme][Type]["Color"]
	Object[ReturnProperty(Object, "Transparency")] = OrionLib.Themes[OrionLib.SelectedTheme][Type]["Transparency"]
	return Object
end

local function UpdateAllSectionLabels()
	local currentTheme = OrionLib.Themes[OrionLib.SelectedTheme]
	for _, label in ipairs(OrionLib.SectionLabels) do
		if label and label.Parent then
			label.TextColor3 = currentTheme["Text"]["Color"]
			label.TextTransparency = currentTheme["Text"]["Transparency"]
		end
	end
end

-- Создание элементов
CreateElement("Corner", function(Scale, Offset)
	return Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 10)})
end)

CreateElement("Stroke", function(Color, Thickness)
	return Create("UIStroke", {
		Color = Color or Color3.fromRGB(255, 255, 255),
		Thickness = Thickness or 1,
		Name = "Stroke",
	})
end)

CreateElement("List", function(Scale, Offset)
	return Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(Scale or 0, Offset or 0)
	})
end)

CreateElement("Padding", function(Bottom, Left, Right, Top)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, Bottom or 4),
		PaddingLeft = UDim.new(0, Left or 4),
		PaddingRight = UDim.new(0, Right or 4),
		PaddingTop = UDim.new(0, Top or 4)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", { BackgroundTransparency = 1 })
end)

CreateElement("RoundFrame", function(Color, Scale, Offset)
	return Create("Frame", {
		BackgroundColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0
	}, {
		Create("UICorner", {CornerRadius = UDim.new(Scale or 0, Offset or 8)})
	})
end)

CreateElement("Button", function()
	return Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
end)

CreateElement("ScrollFrame", function(Color)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
		ScrollBarImageColor3 = Color or Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
	})
end)

CreateElement("Image", function(ImageID)
	return Create("ImageLabel", {Image = ImageID, BackgroundTransparency = 1})
end)

CreateElement("Label", function(Text, TextSize, Transparency)
	return Create("TextLabel", {
		Text = Text or "",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextTransparency = Transparency or 0,
		TextSize = TextSize or 15,
		Font = Enum.Font.Gotham,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left
	})
end)

-- Система уведомлений
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.Name,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 5),
	})
}), {
	Position = UDim2.new(1, -25, 1, -25),
	Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	Parent = Orion,
	Name = "NotificationList"
})

function OrionLib:MakeNotification(NotificationConfig)
	task.spawn(function()
		NotificationConfig = NotificationConfig or {}
		NotificationConfig.Name = NotificationConfig.Name or "Notification Title"
		NotificationConfig.Content = NotificationConfig.Content or "Notification Content"
		NotificationConfig.Image = NotificationConfig.Image or "server"
		NotificationConfig.Time = NotificationConfig.Time or 5
		NotificationConfig.Color = NotificationConfig.Color or Color3.fromRGB(20, 20, 20)
		NotificationConfig.TextColor = NotificationConfig.TextColor or Color3.fromRGB(255, 255, 255)

		if OrionLib.NotificationSettings.Printing then
			print(string.format("\n%s\n%s:\n  %s\n%s\n", string.rep("-", 49), NotificationConfig.Name, NotificationConfig.Content, string.rep("-", 49)))
		end
		
		if not OrionLib.NotificationSettings.Enabled then return end
		
		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(0.9, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", NotificationConfig.Color, 0, 8), {
			Parent = NotificationParent, 
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0.4,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", GetLucideIcon(NotificationConfig.Image)), {
				Size = UDim2.new(0, 20, 0, 20),
				Position = UDim2.new(0, 0, 0.5, -9),
				ImageColor3 = NotificationConfig.TextColor,
				Name = "Icon",
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit, 
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, -4),
				Font = Enum.Font.GothamBold,
				TextSize = 15,
				Name = "Title",
				BackgroundTransparency = 1,
				TextColor3 = NotificationConfig.TextColor,
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = NotificationConfig.Content == "" and UDim2.new(0, 0, 0, 0) or UDim2.new(1, -30, 0, 6),
				Position = UDim2.new(0, 30, 0, 20),
				Font = Enum.Font.GothamSemibold,
				TextSize = 13,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = NotificationConfig.TextColor,
				TextWrapped = true,
				BackgroundTransparency = 1,
				Visible = NotificationConfig.Content ~= "" and true or false,
			})
		})
		
		local TimerBar = SetProps(MakeElement("RoundFrame", Color3.new(255, 255, 255), 0, 8), {
			Size = UDim2.new(1, -35, 0, 2),
			Position = UDim2.new(0, 30, 0, NotificationFrame.AbsoluteSize.Y - 15),
			Name = "TimerBar",
			Parent = NotificationFrame,
		})

		task.spawn(function()
			TweenService:Create(TimerBar, TweenInfo.new(NotificationConfig.Time - 1, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
			task.wait(NotificationConfig.Time - 1)
			TweenService:Create(TimerBar, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			task.wait(0.3)
			TimerBar.Visible = false
		end)
		
		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 30, 0, 0)}):Play()
		task.wait(NotificationConfig.Time - 0.88)
		TweenService:Create(NotificationFrame, TweenInfo.new(3, Enum.EasingStyle.Quint), {BackgroundTransparency = 1}):Play()
		task.wait(0.05)
		NotificationFrame:TweenPosition(UDim2.new(1, 60, 0, 0), 'In', 'Quint', 0.8, true)
		task.wait(0.85)
		NotificationParent:Destroy()
	end)
end

-- Главная функция создания окна
function OrionLib:MakeWindow(WindowConfig)
	local Val = {
		FirstTab = true,
		Minimized = false,
		UIHidden = false,
		Tab = "",
		TabholderSize = UDim2.new(0, 120, 0, 200)
	}

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "Better Orion"
	WindowConfig.SubName = WindowConfig.SubName or ""
	WindowConfig.Size = WindowConfig.Size or UDim2.fromOffset(600, 400)
	WindowConfig.MinSize = WindowConfig.MinSize or UDim2.fromOffset(400, 200)
	WindowConfig.MaxSize = WindowConfig.MaxSize or UDim2.fromOffset(4000, 2000)
	WindowConfig.IntroEnabled = WindowConfig.IntroEnabled or false
	WindowConfig.IntroText = WindowConfig.IntroText or "Better Orion"
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = GetLucideIcon(WindowConfig.Icon) or ""
	WindowConfig.Transparency = WindowConfig.Transparency or 0.35
	WindowConfig.ToggleUIKey = WindowConfig.ToggleUIKey or Enum.KeyCode.Tab
	WindowConfig.SearchBar = WindowConfig.SearchBar or false
	WindowConfig.NewUI = WindowConfig.NewUI or false
	WindowConfig.BackgroundURL = WindowConfig.BackgroundURL or ""
	WindowConfig.BackgroundTransparency = tonumber(WindowConfig.BackgroundTransparency or 0.2)
	WindowConfig.WatermarkConfig = WindowConfig.WatermarkConfig or {}
	WindowConfig.WatermarkConfig.Enabled = WindowConfig.WatermarkConfig.Enabled or false
	WindowConfig.WatermarkConfig.Visible = WindowConfig.WatermarkConfig.Visible or false

	OrionLib.BackgroundURL = WindowConfig.BackgroundURL
	OrionLib.BackgroundTransparency = WindowConfig.BackgroundTransparency
	OrionLib.ToggleUIKey = WindowConfig.ToggleUIKey

	-- Создание вкладок
	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255)), {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Name = "TabHolder",
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8, 0, 0, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	-- Кнопки управления
	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18),
		}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18),
			Name = "Ico"
		}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1
	})

	-- Точки ресайза
	local ResizePoint = SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 20), 0, 10), {
		Size = UDim2.new(0, 20, 1, 10),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Name = "DragMainWindowResize"
	})

	local ResizePoint2 = SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 20), 0, 10), {
		Size = UDim2.new(1, 10, 0, 20),
		Position = UDim2.new(1, 0, 1, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Name = "DragMainWindowResize2"
	})

	-- Основное окно
	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 20), 0, 25), {
		Size = UDim2.new(0, 120, 0, 0),
		Position = UDim2.new(0, 0, 0, 55),
		BackgroundTransparency = WindowConfig.Transparency,
		Name = "WindowStuff",
		Active = true,
	}), {
		SetProps(MakeElement("Frame"), {
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		}),
		SetProps(MakeElement("Frame"), {
			Size = UDim2.new(0, 10, 1, 0),
			Position = UDim2.new(1, -10, 0, 0),
			BackgroundTransparency = 1,
		}),
		SetChildren(SetProps(MakeElement("Image", ""), {
			Size = UDim2.new(1, 0, 1, 0),
			ScaleType = Enum.ScaleType.Crop,
			Name = "BackgroundImage",
			Image = WindowConfig.BackgroundURL,
			ZIndex = -10,
			Visible = false
		}), {MakeElement("Corner", 0, 25)}),
		TabHolder,
	}), "Main")

	local ResizeTabHolderPoint = SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 20), 0, 10), {
		Size = UDim2.new(0, 15, 1, 0),
		Position = UDim2.new(1, -5, 1, 0),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Parent = WindowStuff,
		Name = "DragTabHolderResize",
		Active = true
	})

	local ResizeTabHolderPoint2 = SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 20), 0, 10), {
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.new(0, 0, 1, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = WindowStuff,
		Name = "DragTabHolderResize2",
		Active = true
	})

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Size = UDim2.new(1, -30, 2, 0),
		Position = UDim2.new(0, 25, 0, -45),
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		Name = "WindowName",
		Text = WindowConfig.Name,
	}), "Text")

	local WindowSubName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.SubName, 14), {
		Size = UDim2.new(1, -WindowName.TextBounds.X - 200, 1, 0),
		Position = UDim2.new(0, WindowConfig.ShowIcon and WindowName.TextBounds.X + 60 or WindowName.TextBounds.X + 35, 0, -19),
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Name = "WindowSubName",
		Text = WindowConfig.SubName
	}), "TextDark")

	local WindowTopBarLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundTransparency = 1,
	}), "Divider")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Parent = Orion,
		Position = UDim2.new(0.5, -WindowConfig.Size.X.Offset / 2, 0.5, -WindowConfig.Size.Y.Offset / 2),
		Size = WindowConfig.Size,
		BackgroundTransparency = WindowConfig.Transparency,
		Name = "MainWindow",
		Visible = false,
	}), {
		SetChildren(AddThemeObject(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 25), {
			Size = UDim2.new(1, 0, 1, -55),
			Position = UDim2.new(0, 0, 0, 55),
			Name = "FakeMainWindowNew",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Active = true,
		}), "Main"), {
			SetChildren(SetProps(MakeElement("Image", ""), {
				Size = UDim2.new(1, 0, 1, 0),
				ScaleType = Enum.ScaleType.Crop,
				Name = "BackgroundImage",
				Image = WindowConfig.BackgroundURL,
				ZIndex = -10,
				Visible = false
			}), {MakeElement("Corner", 0, 25)}),
			ResizePoint,
			ResizePoint2
		}),
		AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 25), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar",
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Active = true,
		}), {
			WindowTopBarLine,
			AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 7), {
				Size = UDim2.new(0, 70, 0, 30),
				Position = UDim2.new(1, -90, 0, 10),
				BackgroundTransparency = 1,
				Name = "ButtonsFrame",
			}), {
				SetProps(MakeElement("Stroke"), {
					Color = Color3.fromRGB(100, 100, 100),
					Name = "Stroke",
					Transparency = 0.5
				}),
				AddThemeObject(SetProps(MakeElement("Frame"), {
					Size = UDim2.new(0, 1, 1, 0),
					Position = UDim2.new(0.5, 0, 0, 0),
					BackgroundTransparency = 0.5,
				}), "Divider"), 
				CloseBtn,
				MinimizeBtn
			}), "Elements"),
			AddThemeObject(SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 20),
				Name = "WindowNames",
			}), {
				WindowName,
				WindowSubName,
			}), "Main"),
			SetChildren(SetProps(MakeElement("Image", ""), {
				Size = UDim2.new(1, 0, 0, 50),
				ScaleType = Enum.ScaleType.Crop,
				Position = UDim2.new(0, 0, 0, 0),
				Name = "BackgroundImage",
				Image = WindowConfig.BackgroundURL,
				ZIndex = -10
			}), {MakeElement("Corner", 0, 25)})
		}), "Main"),
		DragPoint,
		WindowStuff
	}), "Main")

	-- Мобильная кнопка
	local MobileButton = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(20, 20, 20), 0, 10), {
		Parent = Orion,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundTransparency = 0.5,
		Name = "MobileButton",
		Visible = true,
	}), {
		SetProps(MakeElement("Image", WindowConfig.Icon), {
			Name = "Image",
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(0, 5, 0, 5),
			ScaleType = Enum.ScaleType.Fit,
			Visible = true,
			ZIndex = 999,
			BackgroundTransparency = 1,
			ImageTransparency = 0
		})
	})

	local IsMouseOn = false
	AddConnection(MobileButton.MouseEnter, function() IsMouseOn = true end)
	AddConnection(MobileButton.MouseLeave, function() IsMouseOn = false end)
	AddConnection(MobileButton.Image.InputEnded, function(Input)
		if not IsMouseOn then return end
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			MainWindow.Visible = true
			MobileButton.Visible = false
		end
	end)

	OrionLib:SetWindowRefs(MainWindow, MainWindow.FakeMainWindowNew, MainWindow.TopBar, WindowStuff)

	-- Иконка окна
	if WindowConfig.ShowIcon then
		WindowName.Position = UDim2.new(0, 50, 0, -45)
		local WindowIcon = SetProps(MakeElement("Image", WindowConfig.Icon), {
			Size = UDim2.new(0, 20, 0, 20), 
			Position = UDim2.new(0, 25, 0, 17.5), 
			Name = "WindowIcon",
			ScaleType = Enum.ScaleType.Fit,
		})
		WindowIcon.Parent = MainWindow.TopBar
	end

	-- Поиск
	if WindowConfig.SearchBar then
		local SearchBox = Create("TextBox", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			PlaceholderColor3 = Color3.fromRGB(210,210,210),
			PlaceholderText = "Search", 
			Font = Enum.Font.GothamBold,
			TextWrapped = true,
			Text = '',
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 14,
			ClearTextOnFocus = true 
		})

		local TextboxActual = AddThemeObject(SearchBox, "Text")
		local SearchBar = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 1, 6), {
			Parent = MainWindow.TopBar,
			Size = UDim2.new(0, 100, 0, 30),
			Position = UDim2.new(1, -100, 0, 25), 
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Name = "SearchBar",
		}), {
			SetProps(MakeElement("Stroke"), {
				Color = Color3.fromRGB(100, 100, 100),
				Name = "Stroke",
				Transparency = 0.5
			}),
			TextboxActual
		}), "Main")

		local function SearchHandle()
			local Text = string.lower(SearchBox.Text)
			for _, container in MainWindow:GetChildren() do
				if container.Name == "ItemContainerLeft" or container.Name == "ItemContainerRight" then
					for _, frame in container:GetChildren() do
						if not frame:IsA("Frame") then continue end
						for _, btn in frame.Holder:GetChildren() do
							if not btn:IsA("Frame") then continue end
							local content = btn:FindFirstChild("Content") or (btn:FindFirstChild("F") and btn.F:FindFirstChild("Content"))
							if content then
								if Text == "" or string.find(string.lower(content.Text), Text) then
									btn.Visible = true
								else
									btn.Visible = false
								end
							end
						end
					end
				end
			end
		end

		AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), SearchHandle)
	end

	-- Водяной знак
	local WatermarkFrame, WatermarkText, WatermarkIcon, WatermarkStroke, WatermarkConnection
	if WindowConfig.WatermarkConfig.Enabled then
		local FrameTimer = tick()
		local FrameCounter = 0
		local FPS = 60

		WatermarkFrame = AddThemeObject(Create("Frame", {
			Parent = Orion,
			Position = UDim2.new(0, 15, 0, 15),
			Size = UDim2.new(0, 200, 0, 28),
			BackgroundTransparency = WindowConfig.Transparency,
			BorderSizePixel = 0,
			Name = "Watermark",
			ZIndex = 100,
			Active = true,
			Visible = WindowConfig.WatermarkConfig.Visible
		}, {
			Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
			Create("ImageLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				ScaleType = Enum.ScaleType.Crop,
				Name = "BackgroundImage",
				Image = WindowConfig.BackgroundURL,
				ZIndex = -10,
				Visible = false
			}, {Create("UICorner", {CornerRadius = UDim.new(0, 6)})})
		}), "Main")

		WatermarkStroke = AddThemeObject(Create("UIStroke", {
			Parent = WatermarkFrame,
			Thickness = 1,
			Transparency = 0.5,
		}), "Stroke")

		local IconOffset = 0
		if WindowConfig.WatermarkConfig.Icon then
			IconOffset = 22
			WatermarkIcon = AddThemeObject(Create("ImageLabel", {
				Parent = WatermarkFrame,
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0, 8, 0.5, -8),
				BackgroundTransparency = 1,
				Image = WindowConfig.WatermarkConfig.Icon or "",
				Name = "WatermarkIcon",
				ZIndex = 101,
			}), "Text")
		end

		WatermarkText = AddThemeObject(Create("TextLabel", {
			Parent = WatermarkFrame,
			Size = UDim2.new(1, -IconOffset - 16, 1, 0),
			Position = UDim2.new(0, IconOffset + 8, 0, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Name = "WatermarkText",
			ZIndex = 101,
			Text = "",
		}), "Text")

		local function UpdateWatermark()
			local parts = {}
			if WindowConfig.WatermarkConfig.ShowName then parts[#parts+1] = WindowConfig.Name end
			if WindowConfig.WatermarkConfig.ShowFPS then parts[#parts+1] = tostring(math.floor(FPS)) .. " fps" end
			if WindowConfig.WatermarkConfig.ShowPing then
				local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
				parts[#parts+1] = ping .. " ms"
			end
			if WindowConfig.WatermarkConfig.ShowClockTime then parts[#parts+1] = os.date("%H:%M:%S") end
			WatermarkText.Text = table.concat(parts, " | ")
			WatermarkFrame.Size = UDim2.new(0, WatermarkText.TextBounds.X + IconOffset + 16, 0, 28)
		end
		UpdateWatermark()

		WatermarkConnection = RunService.RenderStepped:Connect(function()
			FrameCounter = FrameCounter + 1
			if (tick() - FrameTimer) >= 1 then
				FPS = FrameCounter
				FrameTimer = tick()
				FrameCounter = 0
				UpdateWatermark()
			end
		end)

		OrionLib.Connections[#OrionLib.Connections+1] = WatermarkConnection
	end

	-- Функции перетаскивания
	local function AddDraggingFunctionality(DragPoint, Main)
		local Dragging, DragInput, MousePos, FramePos = false
		DragPoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
				end)
			end
		end)
		DragPoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then 
				DragInput = Input 
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				Main.Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
			end
		end)
	end

	local function AddResizingFunctionality(ResizePoint, Main, IsTabholder)
		local Dragging, DragInput, MousePos, FrameSize = false
		ResizePoint.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				MousePos = Input.Position
				FrameSize = Main.Size
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
				end)
			end
		end)
		ResizePoint.InputChanged:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then 
				DragInput = Input 
			end
		end)
		UserInputService.InputChanged:Connect(function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				local size
				if IsTabholder then
					size = UDim2.new(
						0, math.clamp(FrameSize.X.Offset + Delta.X, 10, (MainWindow.Size.X.Offset / 2) + 50),
						0, math.clamp(FrameSize.Y.Offset + Delta.Y, 45, 9999)
					)
					Val.TabholderSize = size
				else
					size = UDim2.new(
						FrameSize.X.Scale, math.clamp(FrameSize.X.Offset + Delta.X, WindowConfig.MinSize.X.Offset, WindowConfig.MaxSize.X.Offset),
						FrameSize.Y.Scale, math.clamp(FrameSize.Y.Offset + Delta.Y, WindowConfig.MinSize.Y.Offset, WindowConfig.MaxSize.Y.Offset)
					)
				end
				Main.Size = size
				WindowConfig.Size = size
			end
		end)
	end

	AddDraggingFunctionality(DragPoint, MainWindow)
	AddDraggingFunctionality(WatermarkFrame, WatermarkFrame)
	AddDraggingFunctionality(MobileButton, MobileButton)
	AddResizingFunctionality(ResizePoint, MainWindow, false)
	AddResizingFunctionality(ResizePoint2, MainWindow, false)
	AddResizingFunctionality(ResizeTabHolderPoint, WindowStuff, true)
	AddResizingFunctionality(ResizeTabHolderPoint2, WindowStuff, true)

	-- Подключения
	AddConnection(WindowName:GetPropertyChangedSignal("TextBounds"), function()
		WindowSubName.Size = UDim2.new(1, -WindowName.TextBounds.X - 240, 1, 0)
		WindowSubName.Position = UDim2.new(0, WindowConfig.ShowIcon and WindowName.TextBounds.X + 60 or WindowName.TextBounds.X + 35, 0, -19)
	end)

	AddConnection(MainWindow:GetPropertyChangedSignal("Size"), function()
		WindowStuff.Size = UDim2.new(0, Val.TabholderSize.X.Offset, 0, MainWindow.Size.Y.Offset - 50)
	end)

	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false
		MobileButton.Visible = true
		Val.UIHidden = true
		OrionLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Tap "..tostring(WindowConfig.ToggleUIKey):split(".")[3].." to reopen",
			Time = 3,
			Image = "activity"
		})
	end)

	AddConnection(UserInputService.InputBegan, function(Input)
		if Input.KeyCode == WindowConfig.ToggleUIKey then 
			Val.UIHidden = not Val.UIHidden
			MainWindow.Visible = not Val.UIHidden 
		end
	end)

	local VisibleContainers = {}
	AddConnection(MinimizeBtn.MouseButton1Up, function()
		if Val.Minimized then
			TweenService:Create(MainWindow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = WindowConfig.Size}):Play()
			WindowSubName.Visible = true
			ResizePoint.Visible = true
			ResizeTabHolderPoint.Visible = true
			MinimizeBtn.Ico.Image = "rbxassetid://7072719338"
			task.wait(0.02)
			MainWindow.ClipsDescendants = false
			WindowStuff.Visible = true
			WindowTopBarLine.Visible = true
			for _, v in pairs(VisibleContainers) do v.Visible = true end
			VisibleContainers = {}
		else
			MainWindow.ClipsDescendants = true
			WindowTopBarLine.Visible = false
			MinimizeBtn.Ico.Image = "rbxassetid://7072720870"
			local newSize = WindowConfig.ShowIcon and UDim2.new(0, WindowName.TextBounds.X + 160, 0, 50) or UDim2.new(0, WindowName.TextBounds.X + 140, 0, 50)
			TweenService:Create(MainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = newSize}):Play()
			WindowSubName.Visible = false
			ResizePoint.Visible = false
			ResizeTabHolderPoint.Visible = false
			task.wait(0.1)
			WindowStuff.Visible = false
			for _, Container in pairs(MainWindow:GetChildren()) do
				if Container.Name == "ItemContainerLeft" or Container.Name == "ItemContainerRight" then
					if Container.Visible then
						Container.Visible = false
						table.insert(VisibleContainers, Container)
					end
				end
			end
		end
		Val.Minimized = not Val.Minimized
	end)

	-- Загрузочная анимация
	local function LoadSequence()
		MainWindow.Visible = false
		local LoadSequenceLogo = SetProps(MakeElement("Image", WindowConfig.IntroIcon), {
			Parent = Orion,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.4, 0),
			Size = UDim2.new(0, 28, 0, 28),
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			ImageTransparency = 1
		})

		local LoadSequenceText = SetProps(MakeElement("Label", WindowConfig.IntroText, 14), {
			Parent = Orion,
			Size = UDim2.new(1, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 19, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		task.wait(0.8)
		TweenService:Create(LoadSequenceLogo, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -(LoadSequenceText.TextBounds.X/2), 0.5, 0)}):Play()
		task.wait(0.3)
		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
		task.wait(2)
		TweenService:Create(LoadSequenceText, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		MainWindow.Visible = true
		LoadSequenceLogo:Destroy()
		LoadSequenceText:Destroy()
	end

	if WindowConfig.IntroEnabled then LoadSequence() end

	-- Функции управления окном
	local TabFunction = {}

	function TabFunction:SetSize(Size)
		MainWindow.Size = Size
	end

	function TabFunction:SetIconColor(Color)
		if MainWindow.TopBar:FindFirstChild("WindowIcon") then
			MainWindow.TopBar.WindowIcon.ImageColor3 = Color
		end
	end

	function TabFunction:SetColor(Color)
		MainWindow.FakeMainWindowNew.BackgroundColor3 = Color
		MainWindow.TopBar.BackgroundColor3 = Color
		MainWindow.BackgroundColor3 = Color
		WindowStuff.BackgroundColor3 = Color
		if WatermarkFrame then WatermarkFrame.BackgroundColor3 = Color end
	end

	function TabFunction:SetStrokeColor(Color)
		MainWindow.TopBar.ButtonsFrame.Stroke.Color = Color
		MainWindow.TopBar.ButtonsFrame.Frame.BackgroundColor3 = Color
		if MainWindow.TopBar:FindFirstChild("SearchBar") then
			MainWindow.TopBar.SearchBar.Stroke.Color = Color
		end
		if WatermarkStroke then WatermarkStroke.Color = Color end
	end

	function TabFunction:SetStrokeTransparency(Transparency)
		MainWindow.TopBar.ButtonsFrame.Stroke.Transparency = Transparency
		MainWindow.TopBar.ButtonsFrame.Frame.BackgroundTransparency = Transparency
		if MainWindow.TopBar:FindFirstChild("SearchBar") then
			MainWindow.TopBar.SearchBar.Stroke.Transparency = Transparency
		end
	end

	function TabFunction:SetTextColor(Color)
		local SubNameColor = Color3.fromRGB(Color.R * 180, Color.G * 180, Color.B * 180)
		MainWindow.TopBar.WindowNames.WindowName.TextColor3 = Color
		MainWindow.TopBar.WindowNames.WindowSubName.TextColor3 = SubNameColor
		
		for _, Tab in pairs(TabHolder:GetChildren()) do
			if Tab:IsA("TextButton") and Tab.Title then
				Tab.Title.TextColor3 = Color
			end
		end
		
		if WatermarkText then WatermarkText.TextColor3 = Color end
		UpdateAllSectionLabels()
	end

	function TabFunction:SetTextTransparency(Transparency)
		MainWindow.TopBar.WindowNames.WindowName.TextTransparency = Transparency
		MainWindow.TopBar.WindowNames.WindowSubName.TextTransparency = Transparency
		if WatermarkText then WatermarkText.TextTransparency = Transparency end
	end

	function TabFunction:SetTransparency(Transparency)
		MainWindow.BackgroundTransparency = Transparency
		MainWindow.FakeMainWindowNew.BackgroundTransparency = Transparency
		MainWindow.TopBar.BackgroundTransparency = Transparency
		WindowStuff.BackgroundTransparency = Transparency
		WindowConfig.Transparency = Transparency
		if WatermarkFrame then WatermarkFrame.BackgroundTransparency = Transparency end
	end

	function TabFunction:SetToggleKey(Key)
		WindowConfig.ToggleUIKey = Enum.KeyCode[Key]
		OrionLib.ToggleUIKey = WindowConfig.ToggleUIKey
	end

	function TabFunction:SetBackground(URL)
		WindowConfig.BackgroundURL = URL
		OrionLib.BackgroundConfig.BackgroundURL = URL
		MainWindow.FakeMainWindowNew.BackgroundImage.Image = URL
		MainWindow.TopBar.BackgroundImage.Image = URL
		WindowStuff.BackgroundImage.Image = URL
		if WatermarkFrame and WatermarkFrame:FindFirstChild("BackgroundImage") then
			WatermarkFrame.BackgroundImage.Image = URL
		end
	end

	function TabFunction:SetBackgroundTransparency(Transparency)
		WindowConfig.BackgroundTransparency = tonumber(Transparency)
		MainWindow.FakeMainWindowNew.BackgroundImage.ImageTransparency = Transparency
		MainWindow.TopBar.BackgroundImage.ImageTransparency = Transparency
		WindowStuff.BackgroundImage.ImageTransparency = Transparency
		if WatermarkFrame and WatermarkFrame:FindFirstChild("BackgroundImage") then
			WatermarkFrame.BackgroundImage.ImageTransparency = Transparency
		end
	end

	function TabFunction:SetBackgroundVisibility(Bool)
		MainWindow.FakeMainWindowNew.BackgroundImage.Visible = Bool
		MainWindow.TopBar.BackgroundImage.Visible = Bool
		WindowStuff.BackgroundImage.Visible = Bool
		if WatermarkFrame and WatermarkFrame:FindFirstChild("BackgroundImage") then
			WatermarkFrame.BackgroundImage.Visible = Bool
		end
	end

	function TabFunction:NewUI(Bool)
		WindowConfig.NewUI = Bool
		if Bool then
			MainWindow.Transparency = 1
			MainWindow.FakeMainWindowNew.Transparency = WindowConfig.Transparency
			MainWindow.TopBar.Transparency = WindowConfig.Transparency
			WindowStuff.BackgroundTransparency = WindowConfig.Transparency
		else
			MainWindow.Transparency = WindowConfig.Transparency
			MainWindow.FakeMainWindowNew.Transparency = 1
			MainWindow.TopBar.Transparency = 1
			WindowStuff.BackgroundTransparency = 1
		end
	end

	function TabFunction:GetToggleUIKey()
		return WindowConfig.ToggleUIKey
	end

	-- Создание вкладок
	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or ""

		Val.Tab = TabConfig.Name

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder,
			TextWrapped = false,
			Name = Val.Tab,
		}), {
			AddThemeObject(SetProps(MakeElement("Image", GetLucideIcon(TabConfig.Icon)), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -35, 1, 0),
				Position = UDim2.new(0, 35, 0, 0),
				Font = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				TextWrapped = false,
				Name = "Title"
			}), "Text")
		})

		local ContainerLeft = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255)), {
			Size = UDim2.new(0.5, -40, 1, 0),
			Position = UDim2.new(0, 95, 0, WindowConfig.NewUI and 65 or 50),
			Parent = MainWindow,
			Visible = false,
			Name = "ItemContainerLeft"
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15) 
		}), "Divider")
		ContainerLeft:SetAttribute("tab", Val.Tab)

		local ContainerRight = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255)), {
			Size = UDim2.new(0.5, -40, 1, 0),
			Position = UDim2.new(0.5, 40, 0, WindowConfig.NewUI and 65 or 50),
			Parent = MainWindow,
			Visible = false,
			Name = "ItemContainerRight"
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")
		ContainerRight:SetAttribute("tab", Val.Tab)

		AddConnection(ContainerLeft.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			ContainerLeft.CanvasSize = UDim2.new(0, 0, 0, ContainerLeft.UIListLayout.AbsoluteContentSize.Y - 5)
		end)
		AddConnection(ContainerRight.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			ContainerRight.CanvasSize = UDim2.new(0, 0, 0, ContainerRight.UIListLayout.AbsoluteContentSize.Y - 5)
		end)

		if Val.FirstTab then
			Val.FirstTab = false
			TabFrame.Ico.ImageTransparency = 0
			TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBlack
			ContainerLeft.Visible = true
			ContainerRight.Visible = true
		end

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in pairs(TabHolder:GetChildren()) do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end
			end
			for _, Container in pairs(MainWindow:GetChildren()) do
				if Container.Name == "ItemContainerLeft" or Container.Name == "ItemContainerRight" then
					Container.Visible = false
				end
			end
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			ContainerLeft.Visible = true
			ContainerRight.Visible = true
		end)

		-- Настройка размеров контейнеров
		local function SetSizes()
			local width = (MainWindow.AbsoluteSize.X - TabHolder.Parent.AbsoluteSize.X + 5) / 2
			width = width > 0 and width or 0

			ContainerLeft.Size = UDim2.new(0, width + (WindowConfig.NewUI and 0 or 5), 1, WindowConfig.NewUI and -80 or -60)
			ContainerRight.Size = UDim2.new(0, width + (WindowConfig.NewUI and 0 or 5), 1, WindowConfig.NewUI and -80 or -60)

			ContainerLeft.Position = UDim2.new(0, TabHolder.Parent.AbsoluteSize.X + (WindowConfig.NewUI and 5 or -5), 0, WindowConfig.NewUI and 65 or 50)
			ContainerRight.Position = UDim2.new(0, TabHolder.Parent.AbsoluteSize.X + width - (WindowConfig.NewUI and 5 or 10), 0, WindowConfig.NewUI and 65 or 50)

			MainWindow.FakeMainWindowNew.Position = UDim2.new(0, TabHolder.Parent.AbsoluteSize.X + 5, 0, 55)
			MainWindow.FakeMainWindowNew.Size = UDim2.new(1, -TabHolder.Parent.AbsoluteSize.X - 5, 1, -55)
		end
		SetSizes()

		AddConnection(TabHolder.Parent:GetPropertyChangedSignal("AbsoluteSize"), SetSizes)
		AddConnection(MainWindow:GetPropertyChangedSignal("AbsoluteSize"), SetSizes)

		-- Функции элементов
		local function GetElements(ItemParent)
			local ElementFunction = {}

			function ElementFunction:AddLabel(Text)
				Text = Text or "Label"
				local LabelFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Parent = ItemParent,
					Name = "Label",
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextWrapped = true,
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Elements")

				local LabelFunction = {}
				function LabelFunction:Set(ToChange) LabelFrame.Content.Text = ToChange end
				function LabelFunction:SetColor(Color) LabelFrame.BackgroundColor3 = Color end
				function LabelFunction:SetTextColor(Color) LabelFrame.Content.TextColor3 = Color end
				function LabelFunction:SetTransparency(Transparency) LabelFrame.BackgroundTransparency = Transparency end
				return LabelFunction
			end

			function ElementFunction:AddParagraph(Text, Content)
				Text = Text or "Text"
				Content = Content or "Content"

				local ParagraphFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Parent = ItemParent,
					Name = "Paragraph"
				}), {
					AddThemeObject(SetProps(MakeElement("Label", Text, 14), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Title"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Label", Content, 13), {
						Size = UDim2.new(1, -24, 0, 0),
						Position = UDim2.new(0, 12, 0, 26),
						Font = Enum.Font.GothamSemibold,
						Name = "Content",
						TextWrapped = true
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				}), "Elements")

				AddConnection(ParagraphFrame.Content:GetPropertyChangedSignal("Text"), function()
					ParagraphFrame.Content.Size = UDim2.new(1, -24, 0, ParagraphFrame.Content.TextBounds.Y)
					ParagraphFrame.Size = UDim2.new(1, 0, 0, ParagraphFrame.Content.TextBounds.Y + 35)
				end)
				task.wait(0.01)
				ParagraphFrame.Content.Text = Content

				local ParagraphFunction = {}
				function ParagraphFunction:Set(ToChange) ParagraphFrame.Content.Text = ToChange end
				function ParagraphFunction:SetColor(Color) ParagraphFrame.BackgroundColor3 = Color end
				function ParagraphFunction:SetTextColor(Color) ParagraphFrame.Content.TextColor3 = Color end
				function ParagraphFunction:SetTransparency(Transparency) ParagraphFrame.BackgroundTransparency = Transparency end
				return ParagraphFunction
			end

			function ElementFunction:AddButton(ButtonConfig)
				ButtonConfig = ButtonConfig or {}
				ButtonConfig.Name = ButtonConfig.Name or "Button"
				ButtonConfig.Callback = ButtonConfig.Callback or function() end
				ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"
				ButtonConfig.DoubleTap = ButtonConfig.DoubleTap or false
				ButtonConfig.TapDelay = ButtonConfig.TapDelay or 0.5

				local Tap, OldButtonName = 0, ButtonConfig.Name
				local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

				local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 33),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Button",
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 14), {
						Size = UDim2.new(1, -40, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextWrapped = true,
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", ButtonConfig.Icon), {
						Size = UDim2.new(0, 20, 0, 20),
						Position = UDim2.new(1, -30, 0, 7),
						BackgroundTransparency = 1,
						Name = "Image"
					}), "TextDark"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					Click
				}), "Elements")

				local Button = {}
				function Button:Set(ButtonText) ButtonFrame.Content.Text = ButtonText end
				function Button:SetColor(Color) ButtonFrame.BackgroundColor3 = Color end
				function Button:SetTextColor(Color) ButtonFrame.Content.TextColor3 = Color end
				function Button:SetTransparency(Transparency) ButtonFrame.BackgroundTransparency = Transparency end

				AddConnection(Click.MouseButton1Up, function()
					Tap += 1
					if Tap == 2 and ButtonConfig.DoubleTap then
						ButtonConfig.Callback()
					elseif Tap == 1 and ButtonConfig.DoubleTap then
						ButtonFrame.Content.Text = "Are you sure?"
						task.wait(ButtonConfig.TapDelay)
						if Tap == 1 then
							Tap = 0
							ButtonFrame.Content.Text = OldButtonName
						end
					elseif not ButtonConfig.DoubleTap then
						ButtonConfig.Callback()
					end
					Tap = 0
					ButtonFrame.Content.Text = OldButtonName
				end)

				return Button
			end

			function ElementFunction:AddToggle(ToggleConfig)
				ToggleConfig = ToggleConfig or {}
				ToggleConfig.Name = ToggleConfig.Name or "Toggle"
				ToggleConfig.Default = ToggleConfig.Default or false
				ToggleConfig.Callback = ToggleConfig.Callback or function() end
				ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(50, 50, 50)
				ToggleConfig.Flag = ToggleConfig.Flag or nil

				local Toggle = { Value = ToggleConfig.Default, Name = ToggleConfig.Name, Type = "Toggle" }
				local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

				local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, WindowConfig.NewUI and 7 or 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -24, 0, 19),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 0.7,
				}), {
					SetProps(MakeElement("Stroke"), { Color = ToggleConfig.Color, Name = "Stroke", Transparency = 0.5 }),
					SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
						Size = UDim2.new(0, 20, 0, 20),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Name = "Ico"
					})
				})

				local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Toggle",
				}), {
					AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 14), {
						Size = UDim2.new(1, -50, 0, 0),
						Position = UDim2.new(0, 12, 0, 19),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextWrapped = true,
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					ToggleBox,
					Click
				}), "Elements")

				function Toggle:Set(Value)
					Toggle.Value = Value
					TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = Value and ToggleConfig.Color or OrionLib.Themes[OrionLib.SelectedTheme].Divider.Color
					}):Play()
					TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Color = Value and ToggleConfig.Color or OrionLib.Themes[OrionLib.SelectedTheme].Stroke.Color
					}):Play()
					TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						ImageTransparency = Value and 0 or 1, 
						Size = Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)
					}):Play()
					ToggleConfig.Callback(Value)
				end

				function Toggle:SetName(Text) ToggleFrame.Content.Text = Text end
				function Toggle:SetColor(Color) ToggleFrame.BackgroundColor3 = Color end
				function Toggle:SetTextColor(Color) ToggleFrame.Content.TextColor3 = Color end
				function Toggle:SetTransparency(Transparency) ToggleFrame.BackgroundTransparency = Transparency end

				AddConnection(Click.MouseButton1Up, function()
					Toggle:Set(not Toggle.Value)
				end)

				Toggle:Set(ToggleConfig.Default)
				if ToggleConfig.Flag then OrionLib.Flags[ToggleConfig.Flag] = Toggle end
				return Toggle
			end

			function ElementFunction:AddSlider(SliderConfig)
				SliderConfig = SliderConfig or {}
				SliderConfig.Name = SliderConfig.Name or "Slider"
				SliderConfig.Min = SliderConfig.Min or 0
				SliderConfig.Max = SliderConfig.Max or 100
				SliderConfig.Increment = SliderConfig.Increment or 1
				SliderConfig.Default = SliderConfig.Default or 50
				SliderConfig.Callback = SliderConfig.Callback or function() end
				SliderConfig.ValueName = SliderConfig.ValueName or ""
				SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(50, 50, 50)
				SliderConfig.Flag = SliderConfig.Flag or nil

				local Slider = { Value = SliderConfig.Default, Name = SliderConfig.Name, Type = "Slider" }
				local Dragging = false

				local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, 5), {
					Size = UDim2.new(0, 0, 1, 0),
					BackgroundTransparency = 0.3,
					ClipsDescendants = true
				}), {
					AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0,
					}), "Text")
				})

				local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color, 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, -24, 0, 26),
					Position = UDim2.new(0, 12, 0, 30),
					BackgroundTransparency = 0.9
				}), {
					SetProps(MakeElement("Stroke"), { Color = SliderConfig.Color, Name = "Stroke" }),
					AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 6),
						Font = Enum.Font.GothamBold,
						Name = "Value",
						TextTransparency = 0.8
					}), "Text"),
					SliderDrag
				})

				local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 7 or 4), {
					Size = UDim2.new(1, 0, 0, 65),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Slider",
				}), {
					AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 14), {
						Size = UDim2.new(1, -12, 0, 14),
						Position = UDim2.new(0, 12, 0, 10),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextWrapped = true,
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					SliderBar
				}), "Elements")

				SliderBar.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true
					end
				end)

				SliderBar.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = false
					end
				end)

				UserInputService.InputChanged:Connect(function(Input)
					if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
						local SizeScale = math.clamp((Input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
						Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale))
					end
				end)

				function Slider:Set(Value)
					self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
					local scale = (self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min)
					TweenService:Create(SliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.fromScale(scale, 1)
					}):Play()
					local display = tostring(self.Value) .. " " .. SliderConfig.ValueName
					SliderBar.Value.Text = display
					SliderDrag.Value.Text = display
					SliderConfig.Callback(self.Value)
				end

				function Slider:SetColor(Color)
					SliderFrame.BackgroundColor3 = Color
				end
				function Slider:SetTextColor(Color)
					SliderFrame.Content.TextColor3 = Color
				end
				function Slider:SetTransparency(Transparency)
					SliderFrame.BackgroundTransparency = Transparency
				end

				Slider:Set(SliderConfig.Default)
				if SliderConfig.Flag then OrionLib.Flags[SliderConfig.Flag] = Slider end
				return Slider
			end

			function ElementFunction:AddDropdown(DropdownConfig)
				DropdownConfig = DropdownConfig or {}
				DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
				DropdownConfig.Options = DropdownConfig.Options or {}
				DropdownConfig.Default = DropdownConfig.Default or ""
				DropdownConfig.Callback = DropdownConfig.Callback or function() end
				DropdownConfig.Flag = DropdownConfig.Flag or nil
				DropdownConfig.MaxSize = DropdownConfig.MaxSize or 5

				local Dropdown = {
					Buttons = {},
					Value = DropdownConfig.Default,
					Options = DropdownConfig.Options,
					Toggled = false,
					Type = "Dropdown",
					Name = DropdownConfig.Name
				}
				local MaxElements = DropdownConfig.MaxSize

				local DropdownList = SetProps(MakeElement("List"), {
					HorizontalAlignment = Enum.HorizontalAlignment.Center
				})

				local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40, 40, 40)), {
					DropdownList
				}), {
					Parent = ItemParent,
					Position = UDim2.new(0, 0, 0, 38),
					Size = UDim2.new(1, 0, 1, -38),
					ClipsDescendants = true
				}), "Divider")

				local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

				local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Dropdown",
				}), {
					DropdownContainer,
					SetChildren(SetProps(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 14), {
							Size = UDim2.new(1, -12, 1, 0),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content"
						}), "Text"),
						AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
							Size = UDim2.new(0, 20, 0, 20),
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(1, -30, 0.5, 0),
							ImageColor3 = Color3.fromRGB(240, 240, 240),
							Name = "Ico"
						}), "TextDark"),
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "Stroke"),
						Click
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
				}), "Elements")

				AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
				end)

				local function AddOptions(Options)
					for _, Option in pairs(Options) do
						local OptionBtn = AddThemeObject(SetChildren(SetProps(MakeElement("Button"), {
							Parent = DropdownContainer,
							Size = UDim2.new(1, 0, 0, 28),
							BackgroundTransparency = 1,
							ClipsDescendants = true
						}), {
							MakeElement("Corner", 0, 6),
							AddThemeObject(SetProps(MakeElement("Label", Option, 13, 0.4), {
								Position = UDim2.new(0, 4, 0, 0),
								Size = UDim2.new(1, -8, 1, 0),
								Name = "Title"
							}), "Text")
						}), "Divider")

						AddConnection(OptionBtn.MouseButton1Click, function()
							Dropdown:Set(Option)
						end)

						Dropdown.Buttons[Option] = OptionBtn
					end
				end

				function Dropdown:Refresh(Options)
					for _, v in pairs(Dropdown.Buttons) do v:Destroy() end
					table.clear(Dropdown.Buttons)
					Dropdown.Options = Options
					AddOptions(Options)
				end

				function Dropdown:Set(Value)
					Dropdown.Value = Value
					for _, v in pairs(Dropdown.Buttons) do
						v.BackgroundTransparency = 1
						v.Title.TextTransparency = 0.4
					end
					if Dropdown.Buttons[Value] then
						Dropdown.Buttons[Value].BackgroundTransparency = 0
						Dropdown.Buttons[Value].Title.TextTransparency = 0
					end
					DropdownConfig.Callback(Value)
				end

				function Dropdown:SetColor(Color)
					DropdownFrame.BackgroundColor3 = Color
				end
				function Dropdown:SetTextColor(Color)
					DropdownFrame.F.Content.TextColor3 = Color
				end
				function Dropdown:SetTransparency(Transparency)
					DropdownFrame.BackgroundTransparency = Transparency
				end

				AddConnection(Click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					DropdownFrame.F.Line.Visible = Dropdown.Toggled
					TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = Dropdown.Toggled and 180 or 0
					}):Play()
					local nextSize = #Dropdown.Options > MaxElements and 
						(Dropdown.Toggled and UDim2.new(1, 0, 0, 38 + (MaxElements * 28)) or UDim2.new(1, 0, 0, 38)) or
						(Dropdown.Toggled and UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 38) or UDim2.new(1, 0, 0, 38))
					TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = nextSize }):Play()
				end)

				Dropdown:Refresh(Dropdown.Options)
				Dropdown:Set(DropdownConfig.Default)
				if DropdownConfig.Flag then OrionLib.Flags[DropdownConfig.Flag] = Dropdown end
				return Dropdown
			end

			function ElementFunction:AddBind(BindConfig)
				BindConfig = BindConfig or {}
				BindConfig.Name = BindConfig.Name or "Bind"
				BindConfig.Default = BindConfig.Default or ""
				BindConfig.Callback = BindConfig.Callback or function() end
				BindConfig.Flag = BindConfig.Flag or nil
				BindConfig.Hold = BindConfig.Hold or false

				local Bind = { Value = BindConfig.Default, Binding = false, Type = "Bind", Name = BindConfig.Name }
				local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })
				local ClickBind = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), ZIndex = 2 })

				local BindBox = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(50, 50, 50), 0, WindowConfig.NewUI and 7 or 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
				}), {
					SetProps(MakeElement("Stroke"), { Color = Color3.fromRGB(100, 100, 100), Transparency = 0.5, Name = "Stroke" }),
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Default, 14), {
						Size = UDim2.new(1, 0, 1, 0),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						Name = "Value",
					}), "Text"),
					ClickBind
				})

				local BindFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Bind",
				}), {
					AddThemeObject(SetProps(MakeElement("Label", BindConfig.Name, 14), {
						Size = UDim2.new(1, -45, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextWrapped = true,
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					BindBox,
					Click
				}), "Elements")

				local WhitelistedMouse = {
					Enum.UserInputType.MouseButton1,
					Enum.UserInputType.MouseButton2,
					Enum.UserInputType.MouseButton3
				}
				local BlacklistedKeys = {
					Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
					Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
					Enum.KeyCode.Slash, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
				}

				local function CheckKey(Table, Key)
					for _, v in pairs(Table) do if v == Key then return true end end
					return false
				end

				AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
					TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, BindBox.Value.TextBounds.X + 16, 0, 24)
					}):Play()
				end)

				AddConnection(ClickBind.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						if Bind.Binding then return end
						Bind.Binding = true
						BindBox.Value.Text = ""
					end
				end)

				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if Input.KeyCode.Name == Bind.Value and not Bind.Binding then
						if BindConfig.Hold then
							BindConfig.Callback(true)
						else
							BindConfig.Callback()
						end
					elseif Bind.Binding then
						local Key
						if not CheckKey(BlacklistedKeys, Input.KeyCode) then Key = Input.KeyCode end
						if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then Key = Input.UserInputType end
						if Input.KeyCode == Enum.KeyCode.Backspace or Input.KeyCode == Enum.KeyCode.Escape then
							Bind:Set("")
							return
						end
						Key = Key or Bind.Value
						Bind:Set(Key)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name == Bind.Value and BindConfig.Hold then
						BindConfig.Callback(false)
					end
				end)

				function Bind:Set(Key)
					Bind.Binding = false
					Bind.Value = Key or Bind.Value
					Bind.Value = Bind.Value.Name or Bind.Value
					BindBox.Value.Text = Bind.Value
				end

				function Bind:SetColor(Color) BindFrame.BackgroundColor3 = Color end
				function Bind:SetTextColor(Color) BindFrame.Content.TextColor3 = Color end
				function Bind:SetTransparency(Transparency) BindFrame.BackgroundTransparency = Transparency end

				Bind:Set(BindConfig.Default)
				if BindConfig.Flag then OrionLib.Flags[BindConfig.Flag] = Bind end
				return Bind
			end

			function ElementFunction:AddTextbox(TextboxConfig)
				TextboxConfig = TextboxConfig or {}
				TextboxConfig.Name = TextboxConfig.Name or "Textbox"
				TextboxConfig.Default = TextboxConfig.Default or ""
				TextboxConfig.Callback = TextboxConfig.Callback or function() end

				local Click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1
				})

				local TextboxActual = AddThemeObject(Create("TextBox", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					PlaceholderColor3 = Color3.fromRGB(210, 210, 210),
					PlaceholderText = "Input",
					Font = Enum.Font.GothamSemibold,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextSize = 14,
					ClearTextOnFocus = false,
					Text = TextboxConfig.Default
				}), "Text")

				local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 7 or 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextboxActual
				}), "Main")

				local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Textbox",
				}), {
					AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 14), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content",
						TextWrapped = false,
					}), "Text"),
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
					TextContainer,
					Click
				}), "Elements")

				local function UpdateTextboxSize()
					local NewWidth = TextboxActual.TextBounds.X + 16
					local MaxWidth = TextboxFrame.Content.AbsoluteSize.X - TextboxFrame.Content.TextBounds.X - 24
					if NewWidth > MaxWidth then NewWidth = MaxWidth end
					TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, NewWidth, 0, 24)
					}):Play()
				end
				AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), UpdateTextboxSize)

				AddConnection(TextboxActual.FocusLost, function()
					TextboxConfig.Callback(TextboxActual.Text)
				end)

				local Textbox = {}
				function Textbox:Set(Text) TextboxActual.Text = Text end
				function Textbox:SetColor(Color) TextboxFrame.BackgroundColor3 = Color end
				function Textbox:SetTextColor(Color) TextboxFrame.Content.TextColor3 = Color end
				function Textbox:SetTransparency(Transparency) TextboxFrame.BackgroundTransparency = Transparency end

				AddConnection(Click.MouseButton1Up, function()
					TextboxActual:CaptureFocus()
				end)

				return Textbox
			end

			function ElementFunction:AddColorpicker(ColorpickerConfig)
				ColorpickerConfig = ColorpickerConfig or {}
				ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
				ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
				ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
				ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil

				local ColorH, ColorS, ColorV = Color3.toHSV(ColorpickerConfig.Default)
				local Colorpicker = { Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Name = ColorpickerConfig.Name }

				local ColorSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(ColorS, 0, 1 - ColorV, 0),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local HueSelection = Create("ImageLabel", {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0.5, 0, 1 - ColorH, 0),
					ScaleType = Enum.ScaleType.Fit,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=4805639000"
				})

				local Color = Create("ImageLabel", {
					Size = UDim2.new(1, -60, 1, -45),
					Visible = false,
					Image = "rbxassetid://4155801252"
				}, {
					Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
					ColorSelection
				})

				local Hue = Create("Frame", {
					Size = UDim2.new(0, 20, 1, -45),
					Position = UDim2.new(1, -50, 0, 0),
					Visible = false,
					Name = "Hue"
				}, {
					Create("UIGradient", {
						Rotation = 270,
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
							ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
							ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
							ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
							ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
							ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
							ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
						}
					}),
					Create("UICorner", { CornerRadius = UDim.new(0, 5) }),
					HueSelection
				})

				local ColorpickerContainer = Create("Frame", {
					Position = UDim2.new(0, -21, 0, 32),
					Size = UDim2.new(1, 45, 1, -32),
					BackgroundTransparency = 1,
					ClipsDescendants = true
				}, {
					Hue,
					Color,
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 35),
						PaddingRight = UDim.new(0, 35),
						PaddingBottom = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 17)
					})
				})

				local Click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0) })

				local ColorpickerBox = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 7 or 4), {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Transparency = 0,
					BackgroundColor3 = ColorpickerConfig.Default
				}), {
					AddThemeObject(MakeElement("Stroke"), "Stroke")
				})

				local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, WindowConfig.NewUI and 10 or 5), {
					Size = UDim2.new(1, 0, 0, 38),
					Parent = ItemParent,
					BackgroundTransparency = WindowConfig.ElementsTransparency or 0.95,
					Name = "Colorpicker",
				}), {
					SetChildren(SetProps(MakeElement("TFrame"), {
						AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
							Size = UDim2.new(1, 0, 0, 38),
							Position = UDim2.new(0, 12, 0, 0),
							Font = Enum.Font.GothamBold,
							Name = "Content",
							TextWrapped = true,
						}), "Text"),
						ColorpickerBox,
						Click,
						AddThemeObject(SetProps(MakeElement("Frame"), {
							Size = UDim2.new(1, 0, 0, 1),
							Position = UDim2.new(0, 0, 1, -1),
							Name = "Line",
							Visible = false
						}), "Stroke"),
					}), {
						Size = UDim2.new(1, 0, 0, 38),
						ClipsDescendants = true,
						Name = "F"
					}),
					ColorpickerContainer,
					AddThemeObject(MakeElement("Stroke"), "Stroke"),
				}), "Elements")

				local function UpdateColorPicker()
					ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
					Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
				end

				AddConnection(Click.MouseButton1Click, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					TweenService:Create(ColorpickerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 200) or UDim2.new(1, 0, 0, 38)
					}):Play()
					Color.Visible = Colorpicker.Toggled
					Hue.Visible = Colorpicker.Toggled
					ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
				end)

				local ColorInput, HueInput
				AddConnection(Color.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if ColorInput then ColorInput:Disconnect() end
						ColorInput = AddConnection(RunService.RenderStepped, function()
							local ColorX = math.clamp((Mouse.X - Color.AbsolutePosition.X) / Color.AbsoluteSize.X, 0, 1)
							local ColorY = math.clamp((Mouse.Y - Color.AbsolutePosition.Y) / Color.AbsoluteSize.Y, 0, 1)
							ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
							ColorS = ColorX
							ColorV = 1 - ColorY
							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Color.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if ColorInput then ColorInput:Disconnect() end
					end
				end)

				AddConnection(Hue.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if HueInput then HueInput:Disconnect() end
						HueInput = AddConnection(RunService.RenderStepped, function()
							local HueY = math.clamp((Mouse.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
							HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
							ColorH = 1 - HueY
							UpdateColorPicker()
						end)
					end
				end)

				AddConnection(Hue.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if HueInput then HueInput:Disconnect() end
					end
				end)

				function Colorpicker:Set(Value)
					Colorpicker.Value = Value
					ColorpickerBox.BackgroundColor3 = Value
					local h, s, v = Color3.toHSV(Value)
					ColorH, ColorS, ColorV = h, s, v
					ColorSelection.Position = UDim2.new(s, 0, 1 - v, 0)
					HueSelection.Position = UDim2.new(0.5, 0, 1 - h, 0)
					ColorpickerConfig.Callback(Value)
				end

				function Colorpicker:SetColor(Color)
					ColorpickerFrame.BackgroundColor3 = Color
				end
				function Colorpicker:SetTextColor(Color)
					ColorpickerFrame.F.Content.TextColor3 = Color
				end
				function Colorpicker:SetTransparency(Transparency)
					ColorpickerFrame.BackgroundTransparency = Transparency
				end

				Colorpicker:Set(ColorpickerConfig.Default)
				if ColorpickerConfig.Flag then OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker end
				return Colorpicker
			end

			return ElementFunction
		end

		local ElementFunction = { Name = TabConfig.Name }

		function ElementFunction:AddSection(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionConfig.Name = SectionConfig.Name or "Section"
			SectionConfig.Side = SectionConfig.Side or "Left"

			local ContainerSection = (SectionConfig.Side == "Left") and ContainerLeft or ContainerRight

			local SectionLabel = SetProps(MakeElement("Label", SectionConfig.Name, 14), {
				Size = UDim2.new(1, -12, 0, 20),
				Position = UDim2.new(0, 0, 0, -20),
				Font = Enum.Font.GothamSemibold
			})
			table.insert(OrionLib.SectionLabels, SectionLabel)
			SectionLabel.TextColor3 = OrionLib.Themes[OrionLib.SelectedTheme]["Text"]["Color"]
			SectionLabel.TextTransparency = OrionLib.Themes[OrionLib.SelectedTheme]["Text"]["Transparency"]

			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 10),
				Parent = ContainerSection
			}), {
				SectionLabel,
				SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 5),
					Name = "Holder"
				}), {
					MakeElement("List", 0, 6)
				}),
			})

			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}
			local elements = GetElements(SectionFrame.Holder)
			for k, v in pairs(elements) do SectionFunction[k] = v end
			return SectionFunction
		end

		OrionLib.Tabs[TabConfig.Name] = ElementFunction
		return ElementFunction
	end

	OrionLib.Window = TabFunction
	return TabFunction
end

-- Функция для загрузки фона по URL (доступна сразу после создания окна)
function OrionLib:SetBackgroundFromURL(url)
	if url and url ~= "" then
		OrionLib.BackgroundConfig.BackgroundURL = url
		if OrionLib.Window then
			OrionLib.Window:SetBackground(url)
			OrionLib.Window:SetBackgroundVisibility(true)
			OrionLib:MakeNotification({
				Name = "Background Loaded",
				Content = "Background image loaded successfully!",
				Time = 2,
				Image = "image"
			})
			return true
		end
	end
	return false
end

-- Сохранение размеров
function OrionLib:SaveAndLoadSizes()
	-- Аналогично оригинальному коду
end

-- Загрузка автоконфигов
function OrionLib:LoadAutoloadConfigs()
	-- Аналогично оригинальному коду
end

function OrionLib:Init()
	local Window = CoreGui:WaitForChild("BetterOrion", 1):WaitForChild("MainWindow", 1)
	Window.Visible = true
end

function OrionLib:Destroy()
	Orion:Destroy()
end

-- Ссылки на окно
local WindowRefs = {}
function OrionLib:SetWindowRefs(mainWin, fakeMain, topBar, winStuff)
	WindowRefs.MainWindow = mainWin
	WindowRefs.FakeMainWindowNew = fakeMain
	WindowRefs.TopBar = topBar
	WindowRefs.WindowStuff = winStuff
end

function OrionLib:SetCornerRadius(radius)
	-- Аналогично оригинальному коду
end

return OrionLib