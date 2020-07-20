
// Guy Ardito


import Foundation

/*
This class is to isolate calls to REST-ful APIs.  A protocol can be abstracted with concrete implementations also providing stub data for testing.

This class is inteded to be used as a singleton via property 'shared'.

Note that this is a class and not a struct so that we can modify self within closures

Note that it excplicity inherits from NSObject to support KVO.

The primary entry point is 'fetchList'

If multiple pages need to be loaded from API, the total count is assigned to variable 'numberOfPagesRemainingToLoad' which is exposed to KVO.

A downloadTask is spawned for each page and, when each completes, it parses the result, adds the objects to 'metaDataList' and decrements 'numberOfPagesRemainingToLoad'.

The observer for 'numberOfPagesRemainingToLoad' checks if the value has gone to zero and, if it has, it calls the 'normalCompletion' block.


*/


class Metadata_Server : NSObject {

	private let lock = NSLock()

	private let urlSession = URLSession(configuration: .default)
	
	
	static let shared = Metadata_Server()
	
	private var metaDataList = [ImageMetadata_M]()
		
	
	typealias NormalFetchCompletion = (_ dataList:[ImageMetadata_M]) -> ()
	typealias ErrorFetchCompletion = (Error) -> ()
	
	var normalCompletion:NormalFetchCompletion? = nil
	

	// MARK: - KVO support
	@objc dynamic private var numberOfPagesRemainingToLoad = 0
	var observation: NSKeyValueObservation?

	
	
	

	
	// MARK: - data retrieval
	
	
	func fetchList(numberOfItemsToRetrieve:Int,
				   normalCompletion:Metadata_Server.NormalFetchCompletion? = nil,
				   errorCompletion:Metadata_Server.ErrorFetchCompletion? = nil) {
		
		
		if numberOfItemsToRetrieve <= 0 {
			normalCompletion?( [ImageMetadata_M]() )
			return
		}
		
		self.normalCompletion = normalCompletion
		
		urlSession.delegateQueue.maxConcurrentOperationCount = 4  // # of cores
				
		observation = observe(\.self.numberOfPagesRemainingToLoad, options: []) { dataServer, observedChange in
			if self.numberOfPagesRemainingToLoad == 0 {
				self.observation = nil
				normalCompletion?(self.metaDataList)
			}
		}
			
		
		metaDataList.removeAll()
		
		let maxItemsPerPage = 100
		
		if numberOfItemsToRetrieve <= maxItemsPerPage {
			numberOfPagesRemainingToLoad = 1
			fetchItemsFor(pageNumber: 1, numberOfItemsToRetrieve: numberOfItemsToRetrieve )
		
		}  else {
			let numberOfPagesToLoad = numberOfItemsToRetrieve / maxItemsPerPage
			let numberOfItemsOnLastPage = numberOfItemsToRetrieve % maxItemsPerPage
			
			numberOfPagesRemainingToLoad = numberOfPagesToLoad
			if numberOfItemsOnLastPage > 0 { numberOfPagesRemainingToLoad += 1 }
			
			for i in 1...numberOfPagesToLoad {
				fetchItemsFor(pageNumber: i, numberOfItemsToRetrieve: maxItemsPerPage )
			}
			
			if numberOfItemsOnLastPage > 0 {
				fetchItemsFor(pageNumber: numberOfPagesToLoad+1, numberOfItemsToRetrieve: numberOfItemsToRetrieve )
			}
		}
	}
	
	
	
	
	private func fetchItemsFor(pageNumber:Int, numberOfItemsToRetrieve:Int) {
				
		// e.g.  https://picsum.photos/v2/list?page=1&limit=5
		var urlComponents = URLComponents(string:"https://picsum.photos/v2/list?page=\(pageNumber)&limit=\(numberOfItemsToRetrieve)")
		
		
		var dataTask: URLSessionDataTask?
		
		var errorMessage = ""
		
		
		guard let url = urlComponents?.url else {
			print("ERROR error creating URLComponents")
			return
		}
		
		
		dataTask = urlSession.dataTask(with: url) { data, response, error in
			defer { dataTask = nil }
			
			if let error = error {
				errorMessage += "DataTask error: " + error.localizedDescription + "\n"
				print("ERROR: \(errorMessage)")
				
			} else if let data = data,
				let response = response as? HTTPURLResponse,
				response.statusCode == 200 {
				
				//print("loaded \(data.count) bytes")
				
				let decoder = JSONDecoder()
				do {
					let topArray = try decoder.decode([ImageMetadata_M].self, from: data)
					// print("loaded \(topArray.count) elements")
					self.lock.lock()
					self.metaDataList += topArray
					self.numberOfPagesRemainingToLoad -= 1  // NB b/c of KVO we must do this *AFTER* adding to the metaDataList
					self.lock.unlock()
					
				} catch let error {
					print("ERROR JSON not formed according to expected schema")
					print(error)
					//errorCompletion?(error)
				}
			}
		}
		
		dataTask?.resume()
		
	}
	
}


