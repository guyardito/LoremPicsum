
// Guy Ardito



import Cocoa
import Quartz

// MARK: - QuickLook stuff



extension DataTable_VC {
	
	
	override func keyDown(with event: NSEvent) {
		let chars = event.characters
		
		if chars == " " {
			self.didTapSpaceBarOn(tableView)
		
		} else {
			super.keyDown(with: event)
		}
	}
	
	
	func tableViewSelectionDidChange(_ notification: Notification) {
		if self.tableView == notification.object as? NSTableView {
			if QLPreviewPanel.sharedPreviewPanelExists()  &&  QLPreviewPanel.shared()?.isVisible ?? false {
				QLPreviewPanel.shared()?.reloadData()
			}
		}
	}
	
	
	func didTapSpaceBarOn(_ tableView: NSTableView) {
		
		if QLPreviewPanel.sharedPreviewPanelExists()  &&  QLPreviewPanel.shared()?.isVisible ?? false {
			QLPreviewPanel.shared()?.orderOut(nil)
			
		} else {
			QLPreviewPanel.shared()?.makeKeyAndOrderFront(nil)
			QLPreviewPanel.shared()?.reloadData()
		}
		
	}
}



extension DataTable_VC : QLPreviewPanelDelegate {
	
	func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
		if event.type == .keyDown {
			self.tableView.keyDown(with: event)
			return true
		}
		
		return false
	}
}



extension DataTable_VC : QLPreviewPanelDataSource {
	
	func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
		
		return self.tableView.selectedRowIndexes.count
	}
	
	
	
	func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
		let row = Array(self.tableView.selectedRowIndexes)[index]
		let rv = metadataItems[row].download_url
		
		return URL(string: rv)! as NSURL
	}
	
	
	override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
		return true
	}
	
	
	override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.dataSource = self
		panel.delegate = self
	}
	
	
	override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
		panel.dataSource = nil
		panel.delegate = nil
	}
}



