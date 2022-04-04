import com.Components.WinComp;
import com.Utils.Signal;
import com.fox.DD.DeleteContent;
/**
* @author SecretFox
*/
class com.fox.DD.DeleteWindow extends WinComp
{
	public var SignalMoved:Signal;
	public function DeleteWindow() 
	{
		super();
		SignalMoved = new Signal();
	}
	
	public function MoveDragReleaseHandler() 
	{
		super.MoveDragReleaseHandler();
		SignalMoved.Emit();
	}

    public function GetContent():DeleteContent
    {
        return DeleteContent(m_Content);
    }
}