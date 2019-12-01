import com.GameInterface.DistributedValue;
import com.GameInterface.InventoryItem;
import com.Utils.Archive;
import com.Utils.LDBFormat;
import com.Utils.Signal;
import mx.utils.Delegate;

class com.fox.dd.Main {
	private var Agentwindow:DistributedValue;
	
	private var delGlyph:DistributedValue;
	private var delTreshHold:DistributedValue;
	static var SIGNETSTRING:String;
	
	static var UpdateCalled:Signal;
	private var buffer;
	
	public static function main(swfRoot:MovieClip):Void {
		var s_app = new Main(swfRoot);
		swfRoot.onLoad = function() {s_app.Load()};
		swfRoot.onUnload = function() {s_app.Unload()};
		swfRoot.OnModuleActivated = function(config:Archive) { s_app.Activate(config); };
		swfRoot.OnModuleDeactivated = function() { return s_app.Deactivate(); };
	}

	public function Main() {
		Agentwindow = DistributedValue.Create("agentSystem_window");
		delGlyph = DistributedValue.Create("DD_DeleteGlyphDistillates");
		delTreshHold = DistributedValue.Create("DD_DeleteTreshold");
		UpdateCalled = new Signal();
		
		switch(LDBFormat.GetCurrentLanguageCode()){
			case "fr":
				SIGNETSTRING = "Distillat";
				return
			case "de":
				SIGNETSTRING = "destillat";
				return
			case "en":
			default:
				SIGNETSTRING = "Distillate";
				return
		}
	}

	public function Load() {
		Agentwindow.SignalChanged.Connect(HookRewards, this);
		UpdateCalled.Connect(CheckForDeletionBuffer, this);
		HookRewards();
	}
	public function Activate(config:Archive){
		delGlyph.SetValue(config.FindEntry("glyphs", true));
		delTreshHold.SetValue(config.FindEntry("treshoold", 400));
	}
	public function Deactivate(){
		var conf:Archive = new Archive();
		conf.AddEntry("glyphs", delGlyph.GetValue());
		conf.AddEntry("treshold", delTreshHold.GetValue());
		return conf
	}
	public function Unload() {
		Agentwindow.SignalChanged.Disconnect(HookRewards, this);
		UpdateCalled.Disconnect(CheckForDeletionBuffer, this);
	}
	
	// bit better than going through inventory whenever new items get added
	private function HookRewards(){
		if (Agentwindow.GetValue()){
			if (!_global.com.fox.dd.Hooked){
				if (!_global.GUI.AgentSystem.AgentSystemContent.prototype.UpdateCurrentMissionVisibility){
					setTimeout(Delegate.create(this, HookRewards), 100);
					return
				}
				// Add delete function to AgentSystemContent, delegate to keep scope
				_global.GUI.AgentSystem.AgentSystemContent.prototype.DeleteDistillates = Delegate.create(this, CheckForDeletionBuffer);
				// Call for it after claiming rewards
				var f = function() {
					arguments.callee.base.apply(this, arguments);
					this.DeleteDistillates();
					
				};
				f.base = _global.GUI.AgentSystem.AgentSystemContent.prototype.SlotCloseMissionReward;
				_global.GUI.AgentSystem.AgentSystemContent.prototype.SlotCloseMissionReward = f;
				
				_global.com.fox.dd.Hooked = true;
			}
		}
	}
	// some delay to ensure player has received the items
	private function CheckForDeletionBuffer(){
		clearTimeout(buffer);
		buffer = setTimeout(Delegate.create(this, CheckForDeletion), 500);
	}
	
	private function CheckForDeletion(){
		var tresHold = delTreshHold.GetValue();
		if (isNaN(tresHold)) return;
		var DelGlyphs = delGlyph.GetValue();
		var backbag:MovieClip = _root.backpack2;
		for (var column in backbag.m_DefaultInventoryBox.m_ItemSlots) {
			for (var row in backbag.m_DefaultInventoryBox.m_ItemSlots[column]) {
				var item:InventoryItem = backbag.m_DefaultInventoryBox.m_ItemSlots[column][row]["m_ItemData"];
				if (item.m_Name.indexOf(SIGNETSTRING) >= 0 &&
					item.m_Deleteable &&
					item.m_TokenCurrencySellPrice1 == 0 &&
					item.m_XP <= tresHold && 
					(DelGlyphs || item.m_Name.toLowerCase().indexOf("glyph") == -1)
				){
					backbag.m_Inventory.DeleteItem(item.m_InventoryPos);
				}
			}
		}
	}
}