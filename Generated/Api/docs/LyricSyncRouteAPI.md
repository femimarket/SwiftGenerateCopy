# LyricSyncRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**lyricSync**](LyricSyncRouteAPI.md#lyricsync) | **POST** /lyric_sync | 


# **lyricSync**
```swift
    open class func lyricSync(userId: String, byColumn: LyricSyncByColumn? = nil, byFields: LyricSyncByFields? = nil, byId: LyricSyncById? = nil, delete: LyricSyncDelete? = nil, paginate: LyricSyncPaginate? = nil, search: LyricSyncSearch? = nil, update: LyricSyncUpdate? = nil, upsert: LyricSyncUpsert? = nil, completion: @escaping (_ data: LyricSyncServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = lyric_sync.ByColumn(column: "column_example", data: [LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")])], value: 123) // LyricSyncByColumn |  (optional)
let byFields = lyric_sync.ByFields(data: [LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")])], fields: [lyric_sync.ByFieldsQuery(path: "path_example", value: "value_example")]) // LyricSyncByFields |  (optional)
let byId = lyric_sync.ById(data: LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")]), id: 123) // LyricSyncById |  (optional)
let delete = lyric_sync.Delete(data: [123]) // LyricSyncDelete |  (optional)
let paginate = lyric_sync.Paginate(data: [LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")])], skip: 123, take: 123) // LyricSyncPaginate |  (optional)
let search = lyric_sync.Search(data: [LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")])], query: "query_example") // LyricSyncSearch |  (optional)
let update = lyric_sync.Update(data: [LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")])], inputs: [lyric_sync.UpdateItem(fields: "TODO", id: 123)]) // LyricSyncUpdate |  (optional)
let upsert = lyric_sync.Upsert(data: [LyricSync(audio: "audio_example", characters: [CharacterAlignment(end: 123, start: 123, text: "text_example")], credit: 123, id: 123, loss: 123, lyrics: "lyrics_example", userId: "userId_example", words: [WordAlignment(end: 123, loss: 123, start: 123, text: "text_example")])]) // LyricSyncUpsert |  (optional)

LyricSyncRouteAPI.lyricSync(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **userId** | **String** |  | 
 **byColumn** | [**LyricSyncByColumn**](LyricSyncByColumn.md) |  | [optional] 
 **byFields** | [**LyricSyncByFields**](LyricSyncByFields.md) |  | [optional] 
 **byId** | [**LyricSyncById**](LyricSyncById.md) |  | [optional] 
 **delete** | [**LyricSyncDelete**](LyricSyncDelete.md) |  | [optional] 
 **paginate** | [**LyricSyncPaginate**](LyricSyncPaginate.md) |  | [optional] 
 **search** | [**LyricSyncSearch**](LyricSyncSearch.md) |  | [optional] 
 **update** | [**LyricSyncUpdate**](LyricSyncUpdate.md) |  | [optional] 
 **upsert** | [**LyricSyncUpsert**](LyricSyncUpsert.md) |  | [optional] 

### Return type

[**LyricSyncServerRequest**](LyricSyncServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

