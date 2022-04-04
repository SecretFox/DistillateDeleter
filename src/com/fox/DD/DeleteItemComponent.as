import com.Components.ItemComponent;
import com.GameInterface.InventoryItem;
import com.Utils.Colors;
import com.Utils.Signal;
/**
* @author SecretFox
*/
[InspectableList("configName", "displayName")]
class com.fox.DD.DeleteItemComponent extends ItemComponent
{
	public var SignalClicked:Signal;
	[Inspectable(defaultValue="", verbose=1)]
	public var configName:String;
	[Inspectable(defaultValue="", verbose=1)]
	public var displayName:String;
	
	public function DeleteItemComponent(name)
	{
		super();
		SignalClicked = new Signal();
	}
	
	public function onPress()
	{
		SignalClicked.Emit(this);
	}
	
	public function SetData(item:InventoryItem, loadDelay:Number)
	{
		item.m_Rarity = _global.Enums.ItemPowerLevel.e_Superior;
		super.SetData(item, loadDelay);
	}
	
	public function SetSelected(state)
	{
		var color:Number;
		state ? color = Colors.e_ColorBorderItemEnchanted : color = Colors.e_ColorBorderItemSuperior;
		SetStrokeColor( color );
		if (m_LevelClip != undefined)
		{
			Colors.ApplyColor( m_LevelClip.m_Frame, color);
		}
	}
}