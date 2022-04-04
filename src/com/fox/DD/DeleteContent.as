import com.Utils.Archive;
import com.Components.WindowComponentContent;
import com.GameInterface.InventoryBase;
import com.Utils.Signal;
import com.Utils.StringUtils;
import com.fox.DD.DeleteItemComponent;
import gfx.controls.ScrollBar;
import gfx.controls.TextArea;
import gfx.controls.TextInput;
import gfx.controls.CheckBox;
import mx.utils.Delegate;
/**
* @author SecretFox
*/
class com.fox.DD.DeleteContent extends WindowComponentContent
{
	private var _config:Archive;
	public var SignalSave:Signal;
	
	private var m_Name:TextField;
	private var selectedItem:DeleteItemComponent;
	private var m_Weapon:DeleteItemComponent;
	private var m_Talisman:DeleteItemComponent;
	private var m_Glyph:DeleteItemComponent;
	private var m_Signet:DeleteItemComponent;
	private var m_Custom:DeleteItemComponent;
	
	private var m_Threshold:TextInput;
	private var m_Enabled:CheckBox;
	private var m_Energized:CheckBox;
	private var m_CustomInput:TextArea;
	private var m_ScrollBar:ScrollBar;
	
	private var m_Save:Button;

	public function DeleteContent() 
	{
		super();
		SignalSave = new Signal();
	}
	
	public function LoadIcons()
	{
		if (!initialized)
		{
			setTimeout(Delegate.create(this, LoadIcons), 100);
			return;
		}
		
		m_Weapon.SetData(InventoryBase.CreateACGItemFromTemplate(9285906, 0, 0, 1));
		m_Talisman.SetData(InventoryBase.CreateACGItemFromTemplate(9285907, 0, 0, 1));
		m_Glyph.SetData(InventoryBase.CreateACGItemFromTemplate(9288064, 0, 0, 1));
		m_Signet.SetData(InventoryBase.CreateACGItemFromTemplate(9288653, 0, 0, 1));
		m_Custom.SetData(InventoryBase.CreateACGItemFromTemplate(8393003, 0, 0, 1));
		
		m_Weapon.SignalClicked.Connect(TypeSelected, this);
		m_Talisman.SignalClicked.Connect(TypeSelected, this);
		m_Glyph.SignalClicked.Connect(TypeSelected, this);
		m_Signet.SignalClicked.Connect(TypeSelected, this);
		m_Custom.SignalClicked.Connect(TypeSelected, this);
		
		m_CustomInput.textField.wordWrap = false;
		var customContent:Array = _config.FindEntryArray("Custom");
		if ( customContent.length > 0 )
		{
			m_CustomInput.text = customContent.join("\r");
		}
		
		m_Save.onRelease = Delegate.create(this, SaveContent);
		TypeSelected(m_Weapon);
		m_Threshold.addEventListener("textChange", this, "OnTextChanged");
	}
	
	private function OnTextChanged()
	{
		var newstr:String = "";
		for (var i = 0; i < m_Threshold.textField.text.length; i++)
		{
			var dec = m_Threshold.textField.text.charCodeAt(i);
			if ( dec >= 48 && dec <= 57 ) newstr += m_Threshold.textField.text.charAt(i);
		}
		m_Threshold.textField.text = newstr;
	}
	
	public function set config(cfg:Archive)
	{
		_config = cfg;
	}
	
	public function get config(): Archive
	{
		return _config
	}
	
	private function TypeSelected(Selected:DeleteItemComponent)
	{
		selectedItem = Selected;
		Selection.setFocus(selectedItem);
		
		m_Weapon.SetSelected(false);
		m_Talisman.SetSelected(false);
		m_Glyph.SetSelected(false);
		m_Signet.SetSelected(false);
		m_Custom.SetSelected(false);
		
		m_CustomInput.visible = false;
		m_Threshold.visible = false;
		m_Enabled.visible = false;
		m_Energized.visible = false;
		m_ScrollBar.visible = false;
		
		if ( selectedItem ) m_Name.text = selectedItem.displayName;
		switch(selectedItem)
		{
			case m_Weapon:
			case m_Talisman:
			case m_Glyph:
			case m_Signet:
				selectedItem.SetSelected(true);
				
				m_Threshold.text = _config.FindEntry(selectedItem.configName+"XP", 50);
				if (isNaN(Number(StringUtils.Strip(m_Threshold.text))))
				{
					m_Threshold.text = "50";
					_config.ReplaceEntry(selectedItem.configName+"XP", 50);
				}
				m_Enabled.selected = _config.FindEntry(selectedItem.configName+"Enabled", false);
				m_Energized.selected = _config.FindEntry(selectedItem.configName+"Energized", false);
				m_Threshold.visible = true;
				m_Enabled.visible = true;
				m_Energized.visible = true;
				break;
			case m_Custom:
				selectedItem.SetSelected(true);
				m_CustomInput.visible = true;
				m_ScrollBar.visible = true;
				break
			default:
		}
		SignalSizeChanged.Emit();
	}
	
	private function GetCustomContent():String
	{
		var newContent:Array = [];
		var contentArray:Array = m_CustomInput.text.split("\r");
		for (var i = 0; i < contentArray.length; i++)
		{
			var entryCheck = StringUtils.Strip(contentArray[i]);
			if ( entryCheck ) // not empty
			{
				if ( contentArray[i].length < 5)
				{
					contentArray[i] = "#" + contentArray[i] + " <-  Must be over 5 characters";
				}
				newContent.push(contentArray[i]);
			}
		}
		return newContent.join("|");
	}
	
	/**
	 * Checks that the line contains 5 or more letters or numbers, and not just wildcards
	 * 
	 */
	private function HasEnoughCharacters(str:String)
	{
		if ( !isNaN(Number(str))) return true;
		var count:Number = 0;
		for (var i = 0; i < str.length; i++)
		{
			// ? is 63 and * 42, white space characters are under 32
			if ( str.charCodeAt(i) > 64 || !isNaN(Number(str.charAt(i))))
			{
				count++;
				if (count >= 5) return true;
			}
			
		}
		return false;
	}

	private function SaveContent()
	{
		Selection.setFocus(selectedItem);
		switch(selectedItem)
		{
			case m_Weapon:
			case m_Talisman:
			case m_Glyph:
			case m_Signet:
				m_Threshold.text = StringUtils.Strip(m_Threshold.text)
				if (isNaN(Number(m_Threshold.text)))
				{
					m_Threshold.text = "50";
				}
				_config.ReplaceEntry(selectedItem.configName+"XP", m_Threshold.text);
				_config.ReplaceEntry(selectedItem.configName+"Enabled", m_Enabled.selected);
				_config.ReplaceEntry(selectedItem.configName+"Energized", m_Energized.selected);
				break;
			case m_Custom:
				_config.DeleteEntry("Custom");
				
				var newContent:Array = [];
				var contentArray:Array = m_CustomInput.text.split("\r");
				for (var i = 0; i < contentArray.length; i++)
				{
					var entryCheck = StringUtils.Strip(contentArray[i]);
					if ( entryCheck != "") // not completely empty line
					{
						if ( contentArray[i].length < 5 || !HasEnoughCharacters(contentArray[i]))
						{
							contentArray[i] = "#" + contentArray[i] + "  <- Must be over 5 letters";
						}
						_config.AddEntry("Custom", contentArray[i]);
						newContent.push(contentArray[i]);
					}
				}
				m_CustomInput.text = newContent.join("\r");
				break;
			default:
		}
		SignalSave.Emit(_config);
	}
}