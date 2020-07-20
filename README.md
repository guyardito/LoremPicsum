# LoremPicsum


// Guy Ardito


NB
	⁃	The UI is an NSTable with one (sortable) column for each piece of data.
	⁃	For some reason the very first time you select a row it automatically de-selects itself, but all subsequent selections work fine.  This is actually my *FIRST*-ever MacOS app (I've been in the iOS world), and some bits around NSTable in particular are different from iOS, so please judge accordingly.



Features
	⁃	image thumbnails in the table (with aspect ratio preserved)
	⁃	image caching of thumbnails
	⁃	quick look for full-size image with zoom and pan
	⁃	API paging for long list requests
	⁃	save full-sized images to file system
	⁃	sort table by author, width, height, or download_url



Usage
	⁃	user can enter and re-enter a value for number of entries in the text box on the upper chrome; negative values will be ignored.
	⁃	user can dynamically adjust the image thumbnail size by moving the slider on the upper chrome
	⁃	user can sort ascending or descending by author, width, height, or url
	⁃	user can select any row (or multiple rows) and tap the spacebar to bring up a QuickLook view; this view also lets user zoom and pan


Design Decisions
	⁃	I provided a live slider to change the thumbnail size to allow user to choose between seeing more items vs seeing more detail; I used personal judgement to choose smallest and largest size balanced against performance and network usage.
	⁃	When saving a file, it is saved to a fixed location ("/Documents/LoremPicsum/saved images") in JPEG format using the id of the file as its name.  The reason against using the SaveDialog is that it's possible that the user has multiple items selected at once and doing it the way I've implemented lets the user save all of those files seamlessly without adversely impacting usability as understood by the description of the program's purpose.


Architecture Decisions
	⁃	I have two "service" classes to handle REST-ful interfacing and manage data: Metadata_Server and Image_Server.
	⁃	the Metadata_Server uses the URLSession's built-in queue to load each page of information; an observer is added so that when all of the pages have loaded it will send the data to the DataTable_VC via a completion closure
	⁃	The average image size is about 3,000 x 2,000.  For the purpose of our thumbnail we download with a width of 500, which is high enough quality to see meaningful detail while also being only about 2% size of original image.  This makes the app very performant while also saving on bandwidth.
	⁃	Image_Server uses an OperationQueue (with tweaked simultaneous count to 5) to resolve thread handing when loading thumbnails for a large number of elements
	⁃	Image_Server employs a hashtable as a simple RAM cache to improve performance while further decreasing bandwidth usage.  This would need to be expanded to do periodic purging if the number of possible entries grows too large, but the Lorem Picsum API maxes out at around 1,000 images which is perfectly fine.
	⁃	in page the API for large data sets, no care is made to arrange the data array according to page order; this seems fine to be because the page order doesn't seem to have any intrinsic meaning AND the user can sort the data based on multiple factors.
	⁃	For simplicity no effort is made to avoid reloading the same page(s) from the API more than once.  This can be accomplished by keeping a list of objects for a page in an array which is then kept in a hashtable keyed on page number.



TBD
	⁃	couldn't get the "download_url" cells to vertically center the text
	⁃	there are a few outstanding AutoLayout warnings I haven’t resolved
	⁃	more robust error handling and reporting


Errata
	⁃	it *seems* like the maximum number of items that can be returned by the service is 993.

