
// Guy Ardito



import Cocoa


/*
This class is the main entry point of interaction with the user.  It interacts with the Metadata_Server and Image_Server, presenting the results in an NSTable.

User can sort on author, width, height, and download_url
This class keeps its own array of ImageMetadata_M to facilitate sorting.
*/


class DataTable_VC : NSViewController {
	
	@IBOutlet weak var tableView: NSTableView!
	
	@IBOutlet weak var sizingSlider: NSSlider!
		
	@IBOutlet weak var statusLabel: NSTextField!
	
	//keep a copy so that we can play with the sorting
	var metadataItems = [ImageMetadata_M]()
	
	
	private enum Columns: String {
		case Author
		case Width
		case Height
		case URL
		case Image
	}
	private var columnsInOrder:[Columns] = [ .Author, .Width, .Height, .URL, .Image ]
	private var sortOrder = Columns.Author
	private var sortAscending = true
	
	
	private var numberOfItemsToRetrieve = 0
	
	private var rowHeight:CGFloat = 60
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self
		
		tableView.target = self
		
		rowHeight = CGFloat(sizingSlider.floatValue)
		
		for directive in [
			(0, Columns.Author.rawValue),
			(1, Columns.Width.rawValue),
			(2, Columns.Height.rawValue),
			(3, Columns.URL.rawValue)
			] {
				tableView.tableColumns[directive.0].sortDescriptorPrototype =
					NSSortDescriptor(key: directive.1, ascending: true)
		}

		statusLabel.stringValue = ""
	}
	

	
	@IBAction func imageSliderChanged(slider:NSSlider) {
		rowHeight = CGFloat(slider.floatValue)
		
		tableView.reloadData()
	}
	
	
	@IBAction func numberOfEntriesChanged(numberField:NSTextField) {
		numberOfItemsToRetrieve = Int(numberField.intValue)
		
		metadataItems.removeAll()
		statusLabel.stringValue = ""
		
		let normalCompletionHandler:Metadata_Server.NormalFetchCompletion = { dataList in
			self.metadataItems = dataList

			DispatchQueue.main.async {
				print("reload, now have \(self.metadataItems.count) items")
				self.statusLabel.stringValue = "\(self.metadataItems.count) items"
				self.sortAndReloadTable()
			}
		}
		
		
		let errorCompletionHandler:Metadata_Server.ErrorFetchCompletion = { error in
			
			DispatchQueue.main.async {
				self.statusLabel.stringValue = "\(error)"
			}
		}
		
		
		Metadata_Server.shared.fetchList(numberOfItemsToRetrieve: numberOfItemsToRetrieve,
									normalCompletion: normalCompletionHandler,
									errorCompletion: errorCompletionHandler )
	}
	
	
	@IBAction func saveFiles(sender:NSButton) {
		
		let alert = NSAlert()
		
		if tableView.selectedRowIndexes.count == 0 {
			alert.alertStyle = NSAlert.Style.warning
			alert.messageText = "Warning"
			alert.informativeText = "No files selected, so no files saved."
		
		} else {
			alert.alertStyle = NSAlert.Style.informational
			alert.messageText = "Status"
			
			let selectedItems = tableView.selectedRowIndexes.map { metadataItems[$0] }
			
			let saveStatus = Image_Server.shared.saveToPersistentStore(imageDataList: selectedItems)
			if saveStatus.success == true {
				if tableView.selectedRowIndexes.count == 1 {
					alert.informativeText = "\(tableView.selectedRowIndexes.count) file saved to Documents/LoremPicsum/saved images"
					
				} else {
					alert.informativeText = "\(tableView.selectedRowIndexes.count) files saved to Documents/LoremPicsum/saved images"
				}
				
			} else {
				alert.informativeText = "Error saving images.  \(saveStatus.message)"
			}
			
		}
		
		alert.addButton(withTitle: "OK")
		alert.runModal()
	}

	
	
	func sortAndReloadTable() {
		metadataItems = contentsOrderedBy(sortOrder, ascending: sortAscending)
		tableView.reloadData()
	}
	

		
	
	
	// MARK: - Sorting
	
	private func contentsOrderedBy(_ orderedBy: Columns, ascending: Bool) -> [ImageMetadata_M] {
		
		switch orderedBy {
		case .Author:
			return metadataItems.sorted { itemComparator(lhs:$0.author, rhs: $1.author, ascending:ascending) }
			
		case .Width:
			return metadataItems.sorted { itemComparator(lhs:$0.width, rhs: $1.width, ascending: ascending) }
			
		case .Height:
			return metadataItems.sorted { itemComparator(lhs:$0.height, rhs: $1.height, ascending:ascending) }
			
		case .URL:
			return metadataItems.sorted { itemComparator(lhs:$0.download_url, rhs: $1.download_url, ascending:ascending) }
		
		default:
			return metadataItems
		}
		
	}
	
	
	
	func itemComparator<T:Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
		return ascending ? (lhs < rhs) : (lhs > rhs)
	}
	

}


// MARK: - DataSource

extension DataTable_VC : NSTableViewDataSource {
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		return metadataItems.count
	}
	
	
	func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
		guard let sortDescriptor = tableView.sortDescriptors.first else {
			return
		}
		
		if let order = Columns(rawValue: sortDescriptor.key!) {
			sortOrder = order
			sortAscending = sortDescriptor.ascending
			metadataItems = contentsOrderedBy(sortOrder, ascending: sortAscending)
			sortAndReloadTable()
		}
	}
}



// MARK: - Delegate

extension DataTable_VC : NSTableViewDelegate {
		
	
	func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
		return rowHeight
	}
	
	
	
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		var text: String = ""
		var cellIdentifier: String = ""
		
		let item = metadataItems[row]

		
		let key = Columns( rawValue: (tableColumn?.identifier)?.rawValue ?? "bad value" )
		switch key {
			case .Author:
				text = item.author
			
			case .Width:
				text = "\(item.width)"

			case .Height:
				text = "\(item.height)"

			case .URL:
				text = item.url

			case .Image:
				text = ""
			
			case .none:
				text = "(bad key)"
				return nil
		}
		
		cellIdentifier = key!.rawValue + "Cell"  // this is our naming convention in the storyboard



		
		if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
			cell.textField?.stringValue = text
			
			// make sure to set the cell to a slug value before retrieving intended value
			cell.imageView?.image = #imageLiteral(resourceName: "broken image.png")

			if key == .Image {
				Image_Server.shared.retrieveImageFor(item:item, size: .Thumbnail)  { image in
					DispatchQueue.main.async { cell.imageView?.image = image }
				}
			}
			
			return cell
		}
		
		return nil
	}
	
}

