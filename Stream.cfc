component accessors="true"{

	// The Java Stream we represent
	property name="jStream";

	// Static Stream Class Access
	variables.coreStream    = createObject( "java", "java.util.stream.Stream" );
	variables.intStream    	= createObject( "java", "java.util.stream.IntStream" );
	variables.longStream    = createObject( "java", "java.util.stream.LongStream" );
	variables.Collectors    = createObject( "java", "java.util.stream.Collectors" );
	variables.Arrays        = createObject( "java", "java.util.Arrays" );

	// Lucee pivot
	variables.isLucee = server.keyExists( "lucee" );

	/**
	 * Construct a stream
	 *
	 * @collection This is an optional collection to build a stream on: List, Array, Struct, Query
	 */
	Stream function init( any collection="" ){
		// If a list, enhance to array
		if( isSimpleValue( arguments.collection ) ){
			arguments.collection = listToArray( arguments.collection );
		}

		// If Array
		if( isArray( arguments.collection ) ){
			variables.jStream = variables.Arrays.stream( 
				javaCast( "java.lang.Object[]", arguments.collection ) 
			);
			return this;
		}
		
		// If Struct
		if( isStruct( arguments.collection ) ){
			
			if( variables.isLucee ){
				variables.jStream = arguments.collection.entrySet().stream();
			} else {
				arguments.collection = createObject( "java", "java.util.HashMap" )
					.init( arguments.collection )
					.entrySet()
					.toArray();
				
				variables.jStream = variables.Arrays.stream( 
					arguments.collection
				);
			}

			return this;
		}

		// If Query
		if( isQuery( arguments.collection ) ){
			// TODO:
		}

		throw( 
			message="Cannot create stream from incoming collection",
			type="InvalidColletionType",
			detail="#getMetadata( arguments.collection ).toString()#" 
		);
	}

	/**
	 * Returns a sequential ordered stream whose elements are the specified values.
	 * Each argument passed to this function will generate the stream from.
	 * 
	 */
	Stream function of(){
		if( arguments.isEmpty() ){
			throw( message="Please pass at least one value", type="InvalidValues" );
		}
		
		// Doing it this way so acf11 is supported
		var sequence = [];
		arguments.each( function( k,v ){
			sequence.append( v );
		} );

		return init( sequence );
	}

	/**
	 * Create a character stream from a string
	 * This won't work on ACF11 due to stupidity
	 * 
	 * @target The string to convert to a stream using its characters 
	 */
	Stream function ofChars( required string target ){
		if( variables.isLucee ){
			variables.jStream = arguments.target.chars();
		} else {
			variables.jStream = variables.Arrays.stream( 
				javaCast( "java.lang.Object[]", listToArray( arguments.target, "" ) )
			);
		}
		return this;
	}

	/**
	 * Create a stream from a file. Every line of the text becomes an element of the stream:
	 *
	 * @path The absolute path of the file to generate a stream from
	 */
	Stream function ofFile( required string path ){

		variables.jStream = createObject( "java", "java.nio.file.Files" ).lines( 
			createObject( "java", "java.nio.file.Paths" ).get( 
				createObject( "java", "java.io.File" ).init( arguments.path ).toURI()
			)
		);

		return this;
	}

	/**
	 * Returns an infinite sequential unordered stream where each element is generated by the provided Supplier. 
	 * This is suitable for generating constant streams, streams of random elements, etc. Please make sure you limit
	 * your stream or this method will work until it reaches the memory limit. Use the <code>limit()</code>
	 * 
	 * @supplier A closure or lambda that will supply the generated elements
	 */
	Stream function generate( required supplier ){
		variables.jStream = variables.jStream.generate( 

			createDynamicProxy(
				new proxies.Supplier( arguments.supplier ),
				[ "java.util.function.Supplier" ]
			)

		);
		return this;
	}

	/**
	 * Returns an infinite sequential ordered Stream produced by iterative application of a function f to an initial element seed, 
	 * producing a Stream consisting of seed, f(seed), f(f(seed)), etc.
	 * The first element (position 0) in the Stream will be the provided seed. For n > 0, the element at position n, 
	 * will be the result of applying the function f to the element at position n - 1.
	 * 
	 * Each f receives the previous seed
	 * 
	 * @seed the initial element
	 * @f a function to be applied to to the previous element to produce a new element
	 * 
	 */
	Stream function iterate( required seed, required f ){
		variables.jStream = variables.jStream.iterate( 
			arguments.seed,
			createDynamicProxy(
				new proxies.UnaryOperator( arguments.f ),
				[ "java.util.function.UnaryOperator" ]
			)
		);
		return this;
	}

	/**
	 * Returns a sequential ordered IntStream from start (inclusive) to end (exclusive) by an incremental step of 1.
	 * See https://docs.oracle.com/javase/8/docs/api/java/util/stream/IntStream.html
	 */
	Stream function range( required numeric start, required numeric end ){
		if( variables.isLucee ){
			variables.jStream = variables.longStream.range(
				javaCast( "long", arguments.start ),
				javaCast( "long", arguments.end )
			);
		} else {
			var a = [];
			for( var x = arguments.start; x lt arguments.end; x++ ){
				a.append( x );
			}
			init( a );
		}

		return this;
	}

	/**
	 * Returns a sequential ordered IntStream from start (inclusive) to end (inclusive) by an incremental step of 1.
	 * See https://docs.oracle.com/javase/8/docs/api/java/util/stream/IntStream.html
	 */
	Stream function rangeClosed( required numeric start, required numeric end ){
		if( variables.isLucee ){
			variables.jStream = variables.longStream.rangeClosed(
				javaCast( "long", arguments.start ),
				javaCast( "long", arguments.end )
			);
		} else {
			var a = [];
			for( var x = arguments.start; x lte arguments.end; x++ ){
				a.append( x );
			}
			init( a );
		}
		
		return this;
	}

	/**
	 * Returns an empty sequential Stream.
	 */
	Stream function empty(){
		if( variables.isLucee ){
			variables.jStream = variables.coreStream.empty();
		} else {
			init();
		}

		return this;
	}

	/**************************************** OPERATIONS ****************************************/

	/**
	 * Returns a stream consisting of the elements of this stream, truncated to be no longer than maxSize in length.
	 * Please see warnings for parallel streams: https://docs.oracle.com/javase/8/docs/api/java/util/stream/Stream.html#limit-long-
	 */
	Stream function limit( required numeric maxSize ){
		variables.jStream = variables.jStream.limit( javaCast( "long", arguments.maxSize ) );
		return this;
	}

	/**
	 * Returns a stream consisting of the distinct elements (according to Object.equals(Object)) of this stream.
	 */
	Stream function distinct(){
		variables.jStream = variables.jStream.distinct();
		return this;
	}

	/**
	 * Returns a stream consisting of the remaining elements of this stream after discarding the first n elements of the stream. If this stream contains fewer than n elements then an empty stream will be returned. 
	 * @n the number of leading elements to skip
	 */
	Stream function skip( required numeric n ){
		variables.jStream = variables.jStream.skip( javaCast( "long", arguments.n ) );
		return this;
	}

	/**
	 * Returns a stream consisting of the elements of this stream, sorted according to natural order.
	 */
	Stream function sorted(){
		variables.jStream = variables.jStream.sorted();
		return this;
	}

	/**
	 * Returns a stream consisting of the results of applying the given function to the elements of this stream. 
	 * @mapper The closure or lambda to map apply to each element
	 */
	Stream function map( required mapper ){
		variables.jStream = variables.jStream.map(
			createDynamicProxy( 
				new proxies.Function( arguments.mapper ), 
				[ "java.util.function.Function" ] 
			)
		);
		return this;
	}

	/**
	 * Returns a stream consisting of the elements of this stream that match the given predicate. 
	 * 
	 * This is an intermediate operation.
	 * 
	 * @predicate a non-interfering, stateless predicate to apply to each element to determine if it should be included
	 */
	Stream function filter( required predicate ){
		variables.jStream = variables.jStream.filter(
			createDynamicProxy( 
				new proxies.Predicate( arguments.predicate ), 
				[ "java.util.function.Predicate" ] 
			)
		);
		return this;
	}
	
	/**************************************** TERMINATORS ****************************************/

	/**
	 * Returns an array containing the elements of this stream.
	 */
	function toArray(){
		return variables.jStream.toArray();
	}


	/**
	 * Returns the count of elements in this stream.
	 */
	numeric function count(){
		return variables.jStream.count();
	}

	/**
	 * This is a short-circuiting terminal operation. 
	 * The behavior of this operation is explicitly nondeterministic; it is free to select any element in the stream. This is to allow for maximal performance in parallel operations; the cost is that multiple invocations on the same source may not return the same result. (If a stable result is desired, use findFirst() instead.)
	 * 
	 * @defaultValue Return this value if the return is null
	 */
	function findAny( defaultValue ){
		var optional = variables.jStream.findAny();
		return getNativeTypeFromOptional( optional ) ?: defaultValue ?: javaCast( "null", "" );
	}

	/**
	 * This is a short-circuiting terminal operation.
	 * 
	 * Returns an Optional describing the first element of this stream, or an empty Optional if the stream is empty. If the stream has no encounter order, then any element may be returned. 
	 * 
	 * @defaultValue Return this value if the return is null
	 */
	function findFirst( defaultValue ){
		var optional = variables.jStream.findFirst();
		return getNativeTypeFromOptional( optional ) ?: defaultValue ?: javaCast( "null", "" );
	}

	/**
	 * Performs an action for each element of this stream. 
	 * 
	 * This is a terminal operation.
	 * 
	 * The behavior of this operation is explicitly nondeterministic. For parallel stream pipelines, this operation does not guarantee to respect the encounter order of the stream, as doing so would sacrifice the benefit of parallelism. For any given element, the action may be performed at whatever time and in whatever thread the library chooses. If the action accesses shared state, it is responsible for providing the required synchronization.
	 * 
	 * @action a non-interfering action to perform on the elements 
	 */
	void function forEach( required action ){
		variables.jStream.forEach(
			createDynamicProxy( 
				new proxies.Consumer( arguments.action ), 
				[ "java.util.function.Consumer" ] 
			)
		);
	}

	/**
	 * Performs an action for each element of this stream, in the encounter order of the stream if the stream has a defined encounter order. 
	 * 
	 * This is a terminal operation.
	 * 
	 * This operation processes the elements one at a time, in encounter order if one exists. Performing the action for one element happens-before performing the action for subsequent elements, but for any given element, the action may be performed in whatever thread the library chooses.
	 * 
	 * @action a non-interfering action to perform on the elements 
	 */
	void function forEachOrdered( required action ){
		variables.jStream.forEachOrdered(
			createDynamicProxy( 
				new proxies.Consumer( arguments.action ), 
				[ "java.util.function.Consumer" ] 
			)
		);
	}

	/**
	 * Performs a reduction on the elements of this stream.
	 * 
	 * This function can run the reduction in 3 modes:
	 * 1 - Accumulation only: Using the accumulation function, and returns the reduced value, if any.
	 * 2 - Accumulation with identity value: Performs a reduction on the elements of this stream, using the provided identity or starting value and an associative accumulation function, and returns the reduced value
	 * 
	 * This is a terminal operation.
	 * 
	 * @accumulator an associative, non-interfering, stateless function for combining two values
	 * @identity the identity value for the accumulating function. If not used, then the accumulator is used in isolation
	 * @defaultValue The default value to return if the reduce() operations prodces a null value
	 */
	function reduce( required accumulator, identity, defaultValue ){
		var proxy = createDynamicProxy( 
			new proxies.BinaryOperator( arguments.accumulator ), 
			[ "java.util.function.BinaryOperator" ] 
		);

		// Accumulator Only
		if( isNull( arguments.identity ) ){
			var optional = variables.jStream.reduce( proxy );
			return getNativeTypeFromOptional( optional ) ?: defaultValue ?: javaCast( "null", "" );
		} 
		// Accumulator + Identity Seed
		else {
			var results = variables.jStream.reduce( arguments.identity, proxy );
			return getNativeType( results ) ?: defaultValue ?: javaCast( "null", "" );
		}
		
	}

	/**
	 * Returns whether any elements of this stream match the provided predicate. 
	 * May not evaluate the predicate on all elements if not necessary for determining the result. 
	 * If the stream is empty then false is returned and the predicate is not evaluated. 
	 * 
	 * This is a terminal operation.
	 * 
	 * @predicate a non-interfering, stateless predicate to apply to elements of this stream
	 */
	boolean function anyMatch( required predicate ){
		return variables.jStream.anyMatch(
			createDynamicProxy( 
				new proxies.Predicate( arguments.predicate ), 
				[ "java.util.function.Predicate" ] 
			)
		);
	}

	/**
	 * Returns whether all elements of this stream match the provided predicate. 
	 * May not evaluate the predicate on all elements if not necessary for determining the result. 
	 * If the stream is empty then true is returned and the predicate is not evaluated. 
	 * 
	 * This is a terminal operation.
	 * 
	 * @predicate a non-interfering, stateless predicate to apply to elements of this stream
	 */
	boolean function allMatch( required predicate ){
		return variables.jStream.allMatch(
			createDynamicProxy( 
				new proxies.Predicate( arguments.predicate ), 
				[ "java.util.function.Predicate" ] 
			)
		);
	}

	/**
	 * A mutable reduction operation that accumulates input elements into a mutable result container, optionally transforming the accumulated result into a final representation after all input elements have been processed. 
	 * By default we will collect to an array.
	 * 
	 * NOTE: the struct type will only work if the collection we are collecting is a struct or an object
	 * 
	 * This is a terminal operation.
	 * 
	 * @type The type to collect: array, list or struct
	 * @keyID If using struct, then we need to know what will be the key value in the collection struct
	 * @valueID If using struct, then we need to know what will be the value key in the collection struct
	 * @overwrite If using struct, then do you overwrite elements if the same key id is found. Defaults is true.
	 * @delimiter The delimiter to use in the list. The default is a comma (,)
	 * 
	 */
	function collect( 
		type="array", 
		string keyID, 
		string valueID,
		boolean overwrite=true,
		delimiter="," 
	){

		switch( arguments.type ){
			// STRUCT
			case "struct" : {
				if( isNull( arguments.keyID ) || isNull( arguments.valueID ) ){
					throw( "Please pass in a 'keyID' and a 'valueID', if not we cannot build your struct." );
				}

				var keyFunction = createDynamicProxy(
					new proxies.Function( function( item ){
						// If CFC, execute the method
						if( isObject( arguments.item ) ){
							return invoke( arguments.item, keyID );
						} 
						// If struct, get the key
						else if( isStruct( arguments.item ) ){
							return arguments.item[ keyID ];
						}
						// Else, just return the item, nothing we can map
						return arguments.item;
					} ),
					[ "java.util.function.Function" ]
				);

				var valueFunction = createDynamicProxy(
					new proxies.Function( function( item ){
						// If CFC, execute the method
						if( isObject( arguments.item ) ){
							return invoke( arguments.item, valueID );
						}
						// If struct, get the key
						else if( isStruct( arguments.item ) ){
							return arguments.item[ valueID ];
						}
						// Else, just return the item, nothing we can map
						return arguments.item;
					} ),
					[ "java.util.function.Function" ]
				);

				var overrideFunction = createDynamicProxy(
					new proxies.BinaryOperator( function( oldValue, newValue ){
						return ( overwrite ? newValue : oldValue );
					} ),
					[ "java.util.function.BinaryOperator" ]
				);
				
				return variables.jStream.collect(
					variables.Collectors.toMap( keyFunction, valueFunction, overrideFunction )
				);
			}

			// Simple String Lists
			case "list" : {
				return arrayToList( 
					variables.jStream.collect( variables.Collectors.toList() ),
					arguments.delimiter
				);
			}

			// ARRAYS
			default : {
				return variables.jStream.collect( variables.Collectors.toList() );
			}
		}
	}
	
	// Shortcut Collectors

	/**
	 * Collect the items to a string list
	 * 
	 * @delimiter The delimiter to use in the list. The default is a comma (,)
	 */
	function collectAsList( delimiter="," ){
		arguments.type = "list";
		return collect( argumentCollection=arguments );
	}

	/**
	 * Collect the items to a struct. Please be sure to map the appropriate key and value identifiers
	 * 
	 * @keyID If using struct, then we need to know what will be the key value in the collection struct
	 * @valueID If using struct, then we need to know what will be the value key in the collection struct
	 * @overwrite If using struct, then do you overwrite elements if the same key id is found. Defaults is true.
	 */
	function collectAsStruct( required keyID, required valueID, boolean overwrite=true ){
		arguments.type = "struct";
		return collect( argumentCollection=arguments );
	}

	/************************************ PRIVATE ************************************/


	/**
	 * This method is in charge of detecting Java native types and converting them to CF Types from
	 * Java Optionals
	 * 
	 * @optional The optional Java object https://docs.oracle.com/javase/8/docs/api/java/util/Optional.html
	 */
	private function getNativeTypeFromOptional( required optional ){
		// Only return results if value is present, else produces a null
		if( optional.isPresent() ){
			var results 	= optional.get();
			return getNativeType( results );
		}
	}

	/**
	 * Return a native CF type from incoming Java type
	 * 
	 * @results The native Java return
	 */
	private function getNativeType( results ){
		if( isNull( arguments.results ) ){
			return;
		}

		var className 	= arguments.results.getClass().getName();
		var isEntrySet 	= isInstanceOf( arguments.results, "java.util.Map$Entry" ) OR isInstanceOf( arguments.results, "java.util.HashMap$Node" ); 

		if( isEntrySet ){
			return {
				"#arguments.results.getKey()#" : arguments.results.getValue()
			};
		}

		return arguments.results;
	}
}