
// Guy Ardito



import Foundation

import Cocoa



/*
This class is to both isolate REST-ful calls and provide for seamless caching.

This class is inteded to be used as a singleton via property 'shared'.

This is a class and not a struct so that we can modify self in closures.

The primary entry point is 'retrieveImageFor'

An OperationQueue is used to manage the potentially large number of simultaneous download requests.

*/


class Image_Server {
	
	lazy var downloadQueue: OperationQueue = {
		var queue = OperationQueue()
		queue.name = "Download queue"
		//queue.maxConcurrentOperationCount = 20  // for testing
		return queue
	}()
	
	
	enum ImageSize {
		case Thumbnail
		case Large
		case Full
	}
	
	
	
	private var memoryCacheForThumbnails = [String:NSImage]()
	
	
	static var shared = Image_Server()
	
	private let lock = NSLock()
	
	
	init() {
		// make sure diretory is created
		createDirectory(named: applicationDirectory)
		
		// make sure subdirectory is created
		createDirectory(named: savedSubdirectory)
		
	}
	
	
	func retrieveImageFor(item:ImageMetadata_M, size:ImageSize, _ completion: @escaping (NSImage) -> () ) {
		
		let width:Int
		
		switch size {
		case .Thumbnail:
			width = 500  // NB this got *MUCH* better performance from the server than smaller values like 300
			
		case .Large:
			width = 1300
			
		case .Full:
			width = item.width
		}
		
		let aspect = item.aspectRatio()
		let downloadString = "\(item.urlStringWithoutSizing())/\(width)/\(Int(Float(width)/aspect))"

		
		if let image = memoryCacheForThumbnails[downloadString] {
			completion(image)
			return
		}
		
		if let url = URL(string:downloadString) {
			startDownload(for: url, completion: completion )
		}
	}
	
	
	
	
	
	
	// MARK: operation queue stuff
		
	class ImageDownloader: Operation {
		
		let sourceURL: URL
		var image: NSImage? = nil
		var isDownloaded = false
		
		
		init(_ sourceURL: URL) {
			self.sourceURL = sourceURL
		}
		
		
		override func main() {
			guard let imageData = try? Data(contentsOf: sourceURL) else { return }
			
			if !imageData.isEmpty {
				image = NSImage(data:imageData)
				isDownloaded = true
			}
		}
	}
	
	
	
	
	private func startDownload(for url: URL, completion: @escaping (NSImage) -> () ) {
		
		let downloader = ImageDownloader(url)
		
		downloader.completionBlock = {
			if downloader.isCancelled {
				return
			}
			
			DispatchQueue.global().async {
				if let image = downloader.image {
					self.lock.lock()
					self.memoryCacheForThumbnails[url.absoluteString] = image
					self.lock.unlock()
					
					completion(image)
				}
			}
		}
				
		downloadQueue.addOperation(downloader)
	}
}





// MARK: - for file persistence

let applicationDirectory = "LoremPicsum"
let cacheSubdirectory = applicationDirectory + "/" + "cache"
let savedSubdirectory = applicationDirectory + "/" + "saved images"


extension Image_Server {
	
	/*
	NOTE: this method should really be built out to do robust error handling, especially to handle some entries failing while others succeed, and returning appropriate values in such a case.
	*/
	
	func saveToPersistentStore( imageDataList: [ImageMetadata_M] ) -> (success:Bool, message:String) {
		
		for imd in imageDataList {
			let filename = "\(imd.id).jpeg"
			
			let filePath = NSString(string: documentsDirectoryPath()).appendingPathComponent(savedSubdirectory + "/" + filename)
			
			//print("save \(filename)")
			retrieveImageFor(item: imd, size: .Full) { image in
				FileManager.default.createFile(atPath: filePath, contents: image.asJPEGData(), attributes: nil)
			}
		}
		
		return ( true, "\(imageDataList.count) files saved." )
	}
}

	
	
	
extension NSImage {
	
	func asJPEGData() -> Data {
		let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
		let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
		let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
		return jpegData
	}
}




fileprivate func documentsDirectoryPath() -> String {
	let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
	let documentsDirectory = paths[0]
	return documentsDirectory
}


fileprivate func createDirectory(named name:String){
	let fileManager = FileManager.default
	let paths = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(name)
	
	if !fileManager.fileExists(atPath: paths){
		try! fileManager.createDirectory(atPath: paths, withIntermediateDirectories: true, attributes: nil)
	
	} else {
		//print("Already exists.")
	}
}





