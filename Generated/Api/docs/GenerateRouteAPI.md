# GenerateRouteAPI

All URIs are relative to *https://api.earnfemi.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**generate**](GenerateRouteAPI.md#generate) | **POST** /generate | 


# **generate**
```swift
    open class func generate(action: GenerateAction, audio: String, credit: Int64, file: String, id: UUID, image: String, model: GenerateModel, prompt: String, requestId: String, status: GenerateStatus, userId: String, completion: @escaping (_ data: Generate?, _ error: Error?) -> Void)
```



### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import Api

let action = GenerateAction() // GenerateAction | 
let audio = "audio_example" // String | 
let credit = 987 // Int64 | 
let file = "file_example" // String | 
let id = 987 // UUID | uuid v7
let image = "image_example" // String | 
let model = GenerateModel() // GenerateModel | 
let prompt = "prompt_example" // String | 
let requestId = "requestId_example" // String | transient, managed by server
let status = GenerateStatus() // GenerateStatus | 
let userId = "userId_example" // String | 

GenerateRouteAPI.generate(action: action, audio: audio, credit: credit, file: file, id: id, image: image, model: model, prompt: prompt, requestId: requestId, status: status, userId: userId) { (response, error) in
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
 **action** | [**GenerateAction**](GenerateAction.md) |  | 
 **audio** | **String** |  | 
 **credit** | **Int64** |  | 
 **file** | **String** |  | 
 **id** | **UUID** | uuid v7 | 
 **image** | **String** |  | 
 **model** | [**GenerateModel**](GenerateModel.md) |  | 
 **prompt** | **String** |  | 
 **requestId** | **String** | transient, managed by server | 
 **status** | [**GenerateStatus**](GenerateStatus.md) |  | 
 **userId** | **String** |  | 

### Return type

[**Generate**](Generate.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json, text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

