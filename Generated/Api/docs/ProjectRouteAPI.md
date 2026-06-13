# ProjectRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**project**](ProjectRouteAPI.md#project) | **POST** /project | 


# **project**
```swift
    open class func project(about: String, audio: String, audioLines: [AudioLine], faqs: [Faq], genre: String, id: UUID, playlist: String, seasons: [Season], summary: String, userId: String, completion: @escaping (_ data: Project?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let about = "about_example" // String | 
let audio = "audio_example" // String | 
let audioLines = [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)] // [AudioLine] | 
let faqs = [Faq(answer: "answer_example", id: 123, question: "question_example")] // [Faq] | 
let genre = "genre_example" // String | 
let id = 987 // UUID | 
let playlist = "playlist_example" // String | 
let seasons = [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)] // [Season] | 
let summary = "summary_example" // String | 
let userId = "userId_example" // String | 

ProjectRouteAPI.project(about: about, audio: audio, audioLines: audioLines, faqs: faqs, genre: genre, id: id, playlist: playlist, seasons: seasons, summary: summary, userId: userId) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **about** | **String** |  | 
 **audio** | **String** |  | 
 **audioLines** | [**[AudioLine]**](AudioLine.md) |  | 
 **faqs** | [**[Faq]**](Faq.md) |  | 
 **genre** | **String** |  | 
 **id** | **UUID** |  | 
 **playlist** | **String** |  | 
 **seasons** | [**[Season]**](Season.md) |  | 
 **summary** | **String** |  | 
 **userId** | **String** |  | 

### Return type

[**Project**](Project.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

