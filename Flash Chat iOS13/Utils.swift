//
//  Utils.swift
//  FlashChat
//
//  Created by Alex Wilson on 2/11/26.
//
import Foundation
import UIKit

func debugLog(_ message: String){
    #if DEBUG
    print(message)
    #endif
}

// MARK: - Simple async image cache
 
/// Loads images from URLs and caches them in memory so the same URL is only
/// fetched once per app session.  Thread-safe for reads; NSCache handles
/// eviction under memory pressure automatically.
final class ImageCache {
 
	static let shared = ImageCache()
	private init() {}
 
	private let cache = NSCache<NSString, UIImage>()
 
	/// Calls `completion` on the **main thread** with the loaded image, or nil on failure.
	func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
		// Return cached image immediately
		if let cached = cache.object(forKey: urlString as NSString) {
			completion(cached)
			return
		}
 
		guard let url = URL(string: urlString) else {
			completion(nil)
			return
		}
 
		URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
			guard let self,
				  let data,
				  let image = UIImage(data: data) else {
				DispatchQueue.main.async { completion(nil) }
				return
			}
			self.cache.setObject(image, forKey: urlString as NSString)
			DispatchQueue.main.async { completion(image) }
		}.resume()
	}
}

