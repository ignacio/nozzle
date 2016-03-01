Nozzle
======

Nozzle is a Lua library that allows to write _filters_ and chain them together into _pipelines_. When data passes through the pipeline, each filter can inspect, modify or reject it.

A pipeline ends in a terminating function (a *sink* if you will), that is just a regular function (receives input, returns output). The output produced by the sink will pass through the pipeline in reverse order.

    filter 1 > filter 2 > filter 3 > sink

Input data flows from left to right until it reaches the sink, and the output data flows from right to left, until the start of the pipeline.

             -- input data -->
    
    filter 1 > filter 2 > filter 3 > sink
    
             <-- output data --

Each filter can act on input, output or both. A filter can decide its input is not valid and stop the pipeline right there.

Pipelines are built by concatenating filters:

    pipeline = first_filter .. another_filter .. sink

Filters can be composed and reused:

    new_filter = filter1 .. filter2
    
    pipeline = new_filter .. sink
    pipeline_2 = new_filter .. another_sink

A pipeline is invoked with any data:

    pipeline("some stuff")

The input data must be available in its entirety up front. A filter can't request more data.

There are two kinds of filters. **Normal** and **Generic** filters. Normal filters are best used in Orbit applications, since they are designed to match the signature of the functions used on *dispatch_get* and *dispatch_post* methods. They always take a table as the first argument in its input and output functions (the rest are whatever Orbit sees fit).

Generic filters don't have that restriction (a table as its first argument). They can be used wherever you want, since they don't care on its input and output arguments. However, they are harder to compose (more on that later).

## Input processing

A filter's input function is any function of the following form:

    function(filter, input, ...)
    end

A **normal** filter can retrieve data out of _input_, process it and store it back in _input_. If the filter needs to stop the pipeline because of invalid data, it just returns a non-nil value. That value (or values) will travel back to the start of the pipeline.
Since the input must be modified in-place, a table is needed to carry the data around.

    local json_filter = filter{ input = function(_, data)
        local ok, req = pcall(json.decode, data.input)
        if not ok then
            return "Invalid json data"
            end
        data.request = req
    end}
    
    local pipeline = json_filter .. function(data) print("I'm just a sink") end
    
    pipeline( {input = "not a json"} )	--> will fail
    pipeline( {input = "[1,2,3]"} ) --> will succeed


A **generic** filter, on the other hand, just receives its input as an argument. It does not need to modify the data in place. It just needs to return the processed data. This sounds better in theory, but it can be difficult to compose generic filter if they don't agree on a protocol beforehand.

Note how we needed to add the _req_ parameter to the sink function. If the sink were to return additional stuff, all filters following it in the pipeline must be aware of that change.

    local json_filter = generic_filter{ input = function(_, input)
        local ok, req = pcall(json.decode, input)
        if not ok then
            return stop, "Invalid json data"
        end
        return input, req
    end}
    
    local pipeline = json_filter .. function(data, req) print("I'm just a sink") end
    
    pipeline( "not a json" )	--> will fail
    pipeline( "[1,2,3]" ) --> will succeed


## Output processing

A filter's output function is any function of the following form (for normal filters):

    function(filter, env, output, ...)
    end

For generic filters, the output filter is a function of this form:

    function(filter, output, ...)
    end

Output processing is essentially the same on normal and generic filters, with the exception of that first argument that normal filters take and the generic ones do not.

Whatever is returned from an output filter is passed back to the previous filter.

## Stock filters

Some stock filters are provided.

### json_validator#

It is a normal input filter that is intended to be used in Orbit applications. It tries to decode the body of a POST as json. If it fails, it replies with http status 400. If it succeeds, places the decoded json data in a field called
_request_ in the environment table. It relies on JSON4Lua.

Since you'll usually want to change the reply when an error occurs, you can pass a callback function to handle json errors. The filter will call that function with the environment table and the raw data. Whatever you return from that callback will be returned by the filter. You also need to set the http status code.

### json_reply#

It is a normal output filter that encodes back to *json* is also provided and it's called *json_reply*. It will set the appropiate content-type headers in the response and if its input is a table, it will encode it in json.
