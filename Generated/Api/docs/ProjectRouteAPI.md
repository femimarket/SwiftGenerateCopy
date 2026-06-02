# ProjectRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**project**](ProjectRouteAPI.md#project) | **POST** /project | 


# **project**
```swift
    open class func project(userId: String, byColumn: ProjectByColumn? = nil, byFields: ProjectByFields? = nil, byId: ProjectById? = nil, delete: ProjectDelete? = nil, paginate: ProjectPaginate? = nil, search: ProjectSearch? = nil, update: ProjectUpdate? = nil, upsert: ProjectUpsert? = nil, completion: @escaping (_ data: ProjectServerRequest?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let userId = "userId_example" // String | 
let byColumn = project.ByColumn(column: "column_example", data: [Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example")], value: 123) // ProjectByColumn |  (optional)
let byFields = project.ByFields(data: [Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example")], fields: [project.ByFieldsQuery(path: "path_example", value: "value_example")]) // ProjectByFields |  (optional)
let byId = project.ById(data: Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example"), id: 123) // ProjectById |  (optional)
let delete = project.Delete(data: [123]) // ProjectDelete |  (optional)
let paginate = project.Paginate(data: [Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example")], skip: 123, take: 123) // ProjectPaginate |  (optional)
let search = project.Search(data: [Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example")], query: "query_example") // ProjectSearch |  (optional)
let update = project.Update(data: [Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example")], inputs: [project.UpdateItem(fields: "TODO", id: 123)]) // ProjectUpdate |  (optional)
let upsert = project.Upsert(data: [Project(about: "about_example", audio: "audio_example", audioLines: [AudioLine(context: "context_example", goal: "goal_example", id: 123, line: "line_example", startTime: 123)], faqs: [Faq(answer: "answer_example", id: 123, question: "question_example")], genre: "genre_example", id: 123, playlist: "playlist_example", seasons: [Season(episodes: [Episode(id: 123, scenes: [Scene(audioLineId: 123, id: 123, shots: [Shot(draftImage: "draftImage_example", finalImage: "finalImage_example", id: 123)], text: "text_example")])], id: 123)], summary: "summary_example", userId: "userId_example")]) // ProjectUpsert |  (optional)

ProjectRouteAPI.project(userId: userId, byColumn: byColumn, byFields: byFields, byId: byId, delete: delete, paginate: paginate, search: search, update: update, upsert: upsert) { (response, error) in
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
 **byColumn** | [**ProjectByColumn**](ProjectByColumn.md) |  | [optional] 
 **byFields** | [**ProjectByFields**](ProjectByFields.md) |  | [optional] 
 **byId** | [**ProjectById**](ProjectById.md) |  | [optional] 
 **delete** | [**ProjectDelete**](ProjectDelete.md) |  | [optional] 
 **paginate** | [**ProjectPaginate**](ProjectPaginate.md) |  | [optional] 
 **search** | [**ProjectSearch**](ProjectSearch.md) |  | [optional] 
 **update** | [**ProjectUpdate**](ProjectUpdate.md) |  | [optional] 
 **upsert** | [**ProjectUpsert**](ProjectUpsert.md) |  | [optional] 

### Return type

[**ProjectServerRequest**](ProjectServerRequest.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

