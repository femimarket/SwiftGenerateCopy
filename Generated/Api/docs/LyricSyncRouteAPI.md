# LyricSyncRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**lyricSync**](LyricSyncRouteAPI.md#lyricsync) | **POST** /lyric_sync | 


# **lyricSync**
```swift
    open class func lyricSync(audio: String, id: UUID, lyrics: String, characters: [CharacterAlignment]? = nil, credit: Int64? = nil, loss: Double? = nil, userId: String? = nil, words: [WordAlignment]? = nil, completion: @escaping (_ data: LyricSync?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let audio = "audio_example" // String | 
let id = 987 // UUID | 
let lyrics = "lyrics_example" // String | 
let characters = [CharacterAlignment(end: 123, start: 123, text: "text_example")] // [CharacterAlignment] |  (optional)
let credit = 987 // Int64 |  (optional)
let loss = 987 // Double |  (optional)
let userId = "userId_example" // String |  (optional)
let words = [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")] // [WordAlignment] |  (optional)

LyricSyncRouteAPI.lyricSync(audio: audio, id: id, lyrics: lyrics, characters: characters, credit: credit, loss: loss, userId: userId, words: words) { (response, error) in
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
 **audio** | **String** |  | 
 **id** | **UUID** |  | 
 **lyrics** | **String** |  | 
 **characters** | [**[CharacterAlignment]**](CharacterAlignment.md) |  | [optional] 
 **credit** | **Int64** |  | [optional] 
 **loss** | **Double** |  | [optional] 
 **userId** | **String** |  | [optional] 
 **words** | [**[WordAlignment]**](WordAlignment.md) |  | [optional] 

### Return type

[**LyricSync**](LyricSync.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

