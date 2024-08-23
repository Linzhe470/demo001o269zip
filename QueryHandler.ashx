<%@ WebHandler Language = "C#" Class="QueryHandler" %>

using System;
using System.IO;
using System.Net;
using System.Web;
using System.Collections.Specialized;

public class QueryHandler : IHttpHandler
{

    public void ProcessRequest(HttpContext context)
    {

        //由aspx改成ashx時的轉換
        HttpRequest Request = context.Request;
        HttpResponse Response = context.Response;
        // HttpServerUtility Server = context.Server;
        // System.Web.SessionState.HttpSessionState Session = context.Session;
        //ServicePointManager.SecurityProtocol = SecurityProtocolType.Ssl3 | SecurityProtocolType.Tls | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls12;


        Response.Clear();
        // 檢查是否為 POST 請求
        if (context.Request.HttpMethod == "POST")
        {
            try
            {


                // // 印出 header 資訊
                // int loop1, loop2;
                // NameValueCollection coll;

                // // Load Header collection into NameValueCollection object.
                // coll = Request.Headers;

                // // Put the names of all keys into a string array.
                // String[] arr1 = coll.AllKeys;
                // for (loop1 = 0; loop1 < arr1.Length; loop1++)
                // {
                //     Response.Write("Key: " + arr1[loop1]);
                //     // Get all values under this key.
                //     String[] arr2 = coll.GetValues(arr1[loop1]);
                //     for (loop2 = 0; loop2 < arr2.Length; loop2++)
                //     {
                //         Response.Write("Value " + loop2 + ": " + arr2[loop2] + "___");
                //     }
                // }

                // 驗證呼叫此程式的網址是否符合白名單
                string RefererValue = Request.Headers["Referer"];
                string[] allowReferes = { "https://rw3d.chuanhwa.com.tw/", "https://demo.chuanhwa.com.tw/" };
                bool validPassed = false;
                foreach (string referer in allowReferes)
                {
                    if (RefererValue.Contains(referer))
                    {
                        validPassed = true;
                    }
                }

                if (validPassed)
                {
                    // 將所有查詢參數傳在 header 中
                    string actionkey = Request.Headers["x-rw-api-key"];
                    string buffer_distances = Request.Headers["x-rw-api-buffer-meters"];
                    string lng = Request.Headers["x-rw-api-lng"];
                    string lat = Request.Headers["x-rw-api-lat"];
                    string buffer_geometry = Request.Headers["x-rw-api-buffer-geom"];
                    string postData = "";
                    string targetUrl = "";


                    switch (actionkey)
                    {
                        case "buffer":

                            // POST 資料
                            postData = "geometries=" + lng + "%2C+" + lat + "&inSR=4326&outSR=4326&bufferSR=3826&distances=" + buffer_distances + "&unit=&unionResults=true&geodesic=true&f=pjson";

                            // 設定目標 URL
                            targetUrl = "https://www.leica.com.tw/arcgiswa/rest/services/Utilities/Geometry/GeometryServer/buffer";

                            break;
                        case "nearbylocation":

                            // POST 資料
                            postData = "where=" + HttpUtility.UrlEncode("1=1") + "&text=&objectIds=&time=&geometry=" + HttpUtility.UrlEncode(buffer_geometry);
                            postData += "&geometryType=esriGeometryPolygon&inSR=4326&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Foot";
                            postData += "&relationParam=&outFields=" + HttpUtility.UrlEncode("樹籍編碼,樹種名稱,樹高") + "&returnGeometry=true";
                            postData += "&returnTrueCurves=false&maxAllowableOffset=&geometryPrecision=&outSR=4326&havingClause=&returnIdsOnly=false";
                            postData += "&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false";
                            postData += "&gdbVersion=&historicMoment=&returnDistinctValues=false&resultOffset=&resultRecordCount=&returnExtentOnly=false";
                            postData += "&datumTransformation=&parameterValues=&rangeValues=&quantizationParameters=&featureEncoding=esriDefault&f=pjson";

                            // 設定目標 URL
                            targetUrl = "https://www.leica.com.tw/arcgiswa/rest/services/TaipeiTree/TreeFrontEndService/MapServer/0/query";

                            break;
                        case "googleplacenearby":

                            // POST 資料
                            postData = @"{
                                    includedTypes: ['convenience_store'],
                                    languageCode : 'zh-TW',
                                    maxResultCount: 20,
                                    locationRestriction: {
                                        circle:  {
                                            center:   {
                                                latitude:" + lat + @",
                                                longitude: " + lng + @"
                                            },
                                            radius: " + buffer_distances + @"
                                        }
                                    }
                                } ";
                            // 設定目標 URL
                            targetUrl = "https://places.googleapis.com/v1/places:searchNearby";

                            break;
                        default:

                            break;
                    }

                    // 建立 WebRequest
                    HttpWebRequest request = (HttpWebRequest)WebRequest.Create(targetUrl);
                    request.Method = "POST";

                    switch (actionkey)
                    {
                        case "googleplacenearby":
                            request.ContentType = "application/json;";
                            request.Headers.Add("X-Goog-Api-Key", "AIzaSyCTVjwadqoqlEXRJ-LnzKLStFsWi_msKrM");
                            request.Headers.Add("X-Goog-FieldMask", "places.displayName,places.location,places.formattedAddress");
                            break;
                        default:
                            request.ContentType = "application/x-www-form-urlencoded; charset=utf-8";
                            break;
                    }


                    // 將 POST 資料傳遞到目標伺服器
                    using (StreamWriter writer = new StreamWriter(request.GetRequestStream()))
                    {
                        writer.Write(postData);
                    }

                    // 接收來自目標伺服器的回應
                    using (HttpWebResponse response = (HttpWebResponse)request.GetResponse())
                    {
                        context.Response.ContentType = response.ContentType;

                        using (StreamReader reader = new StreamReader(response.GetResponseStream()))
                        {
                            // 將回應資料返回給用戶端
                            context.Response.Write(reader.ReadToEnd());
                        }
                    }
                }
                else
                {
                    context.Response.StatusCode = 405;
                    context.Response.Write("Not Allowed");
                }

            }
            catch (Exception ex)
            {
                // 處理例外狀況
                context.Response.StatusCode = 500;
                context.Response.Write("Error: " + ex.Message);
            }
        }
        else
        {
            // 如果不是 POST 請求，返回錯誤訊息
            context.Response.StatusCode = 405;
            context.Response.Write("Method Not Allowed");
        }
        Response.End();


    }

    public bool IsReusable
    {
        get
        {
            return false;
        }
    }


}