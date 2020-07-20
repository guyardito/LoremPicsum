
// Guy Ardito



import Foundation

/*
This struct is just model for the data provided by the Lorem Picsum API.
*/


struct ImageMetadata_M : Codable {
	
	var id = "-1"
	var author = "(uninitialized)"
	var width = -1
	var height = -1
	var url = "(uninitialized)"
	var download_url = "(uninitialized)"  // https://picsum.photos/id/1002/4312/2868
	
	
	
	// value not cached because it's typically only used once during processing
	func aspectRatio() -> Float {  // width / height
		let sc = download_url.split(separator: "/")

		let width = Float( sc[4] )
		let height = Float( sc[5] )
		
		return width! / height!
	}
	
	
	
	// that is, the url WITHOUT sizing information
	func urlStringWithoutSizing() -> String {
		let sc = download_url.split(separator: "/")
		
		return "\(sc[0])//\(sc[1])/\(sc[2])/\(sc[3])"
	}
	
	
}

