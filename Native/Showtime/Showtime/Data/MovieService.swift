/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import JavaScriptCore

let movieUrl = "https://itunes.apple.com/us/rss/topmovies/limit=50/json"

lazy var context: JSContext? = {
  let context = JSContext()
  
  // First, you load the common.js file from the application bundle, which contains the JavaScript code you want to access.
  guard let
    commonJSPath = Bundle.main.path(forResource: "common", ofType: "js") else {
      print("Unable to read resource files.")
      return nil
  }
  
  // After loading the file, the context object will evaluate its contents by calling context.evaluateScript(), passing in the file contents for the parameter.
  do {
    let common = try String(contentsOfFile: commonJSPath, encoding: String.Encoding.utf8)
    _ = context?.evaluateScript(common)
  } catch (let error) {
    print("Error while processing script file: \(error)")
  }
  
  return context
}()

class MovieService {
  
  func loadMoviesWith(limit: Double, onComplete complete: @escaping ([Movie]) -> ()) {
    guard let url = URL(string: movieUrl) else {
      print("Invalid url format: \(movieUrl)")
      return
    }
    
    URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data = data, let jsonString = String(data: data, encoding: String.Encoding.utf8) else {
        print("Error while parsing the response data.")
        return
      }
      
      let movies = self.parse(response: jsonString, withLimit: limit)
      complete(movies)
      }.resume()
  }
  
  func parse(response: String, withLimit limit: Double) -> [Movie] {
    // First, you make sure the context object is properly initialized. If there were any errors during the setup (e.g.: common.js was not in the bundle), there’s no point in resuming.
    guard let context = context else {
      print("JSContext not found.")
      return []
    }
    
    // You ask the context object to provide the parseJSON() method. As mentioned previously, the result of the query will be wrapped in a JSValue object. Next, you invoke the method using call(withArguments:), where you specify the arguments in an array format. Finally, you convert the JavaScript value to an array.
    let parseFunction = context.objectForKeyedSubscript("parseJson")
    guard let parsed = parseFunction?.call(withArguments: [response]).toArray() else {
      print("Unable to parse JSON")
      return []
    }
    
    // filterByLimit() returns the list of movies that fit the given price limit.
    let filterFunction = context.objectForKeyedSubscript("filterByLimit")
    let filtered = filterFunction?.call(withArguments: [parsed, limit]).toArray()
    
    // So you’ve got the list of movies, but there’s still one missing piece: filtered holds a JSValue array, and you need to map them to the native Movie type.
    return []
  }
  
}
