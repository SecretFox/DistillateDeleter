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
	static var DISTSTRING:String;
	
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
				DISTSTRING = "Distillat";
				return
			case "de":
				DISTSTRING = "destillat";
				return
			case "en":
			default:
				DISTSTRING = "Distillate";
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
		delTreshHold.SetValue(config.FindEntry("treshold", 400));
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
	
	// small delay for agenttweaks support
	private function HookRewards(){
		if (Agentwindow.GetValue()){
			if (!_global.GUI.AgentSystem.AgentSystemContent.prototype.DeleteDistillates){
				if (!_global.GUI.AgentSystem.AgentSystemContent.prototype.SlotCloseMissionReward){
					setTimeout(Delegate.create(this, HookRewards), 100);
					return
				}
				_global.GUI.AgentSystem.AgentSystemContent.prototype.DeleteDistillates = Delegate.create(this, CheckForDeletionBuffer);
				// Call for it after claiming rewards
				var f = function() {
					arguments.callee.base.apply(this, arguments);
					this.DeleteDistillates();
				};
				f.base = _global.GUI.AgentSystem.AgentSystemContent.prototype.SlotCloseMissionReward;
				_global.GUI.AgentSystem.AgentSystemContent.prototype.SlotCloseMissionReward = f;
			}
			setTimeout(Delegate.create(this, HookAgentTweaks), 500);
		}
	}
	private function HookAgentTweaks(){
		if (_root.agentsystem.m_Window.m_Content.m_MissionList.u_acceptAll){
			if (!_root.agentsystem.m_Window.m_Content.m_MissionList.u_acceptAll.Hook){
				_root.agentsystem.m_Window.m_Content.m_MissionList.u_acceptAll.addEventListener("click", this, "CheckForDeletionBuffer");
				_root.agentsystem.m_Window.m_Content.m_MissionList.u_acceptAll.Hook = true;
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
				if (item.m_Name.indexOf(DISTSTRING) >= 0 &&
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