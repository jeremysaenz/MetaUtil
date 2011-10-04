package com.leedostudios.metadata
{
    import flash.utils.Dictionary;
    import flash.utils.describeType;

    public class Creator implements ICreator
    {
        //_____________________________________________________________________
        //	Static
        //_____________________________________________________________________
        /**
         * Simple singleton for convenience
         */
        public static const instance:Creator = new Creator();

        //_____________________________________________________________________
        //	ICreator Implementation
        //_____________________________________________________________________
        public function create(clazz:Class):*
        {
            // instantiate the class
            // todo: support construtor arguments
            var instance:* = new clazz();

            // do a describe type if it is not in the cache
            if (!definitionCache[clazz])
                definitionCache[clazz] = describe(clazz);

            // loop over all of
            var target:MetaTarget = definitionCache[clazz];

            for (var i:int = 0; i < _source.length; i++)
            {
                var namedProcessor:NamedProcessor = _source[i];

                for(var prop:String in target.properties)
                {
                    var arguments:Object = target.properties[prop][namedProcessor.name];
                    if(arguments)
                        namedProcessor.processor.execute(instance,prop,arguments);
                }

            }

            return instance;
        }

        public function addProcessor(name:String, value:IMetaProcessor):void
        {
            var p:NamedProcessor = new NamedProcessor();
            p.name = name;
            p.processor = value;
            
            _source.push(p);
        }

        public function addProcessorAt(name:String, value:IMetaProcessor, index:int):void
        {
            var p:NamedProcessor = new NamedProcessor();
            p.name = name;
            p.processor = value;

            _source.splice(index, 0, p);
        }

        public function getProcessorAt(index:int):IMetaProcessor
        {
            var p:NamedProcessor = _source[index];
            if(p) return p.processor;
            else return null;
        }

        public function removeProcessorAt(index:int):IMetaProcessor
        {
            return _source.splice(index, 1);
        }
        
        //_____________________________________________________________________
        //	Constructor
        //_____________________________________________________________________
        public function Creator()
        {
            _source = [];
        }

        //_____________________________________________________________________
        //	Protected Statics
        //_____________________________________________________________________
        protected static var definitionCache:Dictionary = new Dictionary();

        //_____________________________________________________________________
        //	Protected Properties
        //_____________________________________________________________________
        protected var _source:Array;

        //_____________________________________________________________________
        //	Protected Methods
        //_____________________________________________________________________
        protected function describe(value:Object):MetaTarget
        {
            var target:MetaTarget = new MetaTarget();
            target.definition = describeType(value);

            // we only want to parse these out once per class
            for each (var node:XML in target.definition.factory.*.(name() == 'variable' || name() == 'accessor'))
            {
                var metatags:Dictionary = new Dictionary();
                target.properties[node.@name.toString()] = metatags;

                trace(node.@name);

                for each(var tag:XML in node.elements("metadata"))
                {
                    var args:Object = {};
                    metatags[tag.@name.toString()] = args;
                    for each(var arg:XML in tag.elements("arg"))
                    {
                        args[arg.@key.toString()] = arg.@value.toString();
                    }
                }
            }
            return target;
        }
    }
}

import com.leedostudios.metadata.IMetaProcessor;

import flash.utils.Dictionary;

internal class MetaTarget
{
    /**
     * Dictionary of properties, with the prop id as the key, and
     * the property args as the value respectively
     */
    public var properties:Dictionary = new Dictionary();

    /**
     * Definition cache
     */
    public var definition:XML;
}

internal class NamedProcessor
{
    /**
     * The processor that the metadata tag represents
     */
    public var processor:IMetaProcessor;

    /**
     * Name of the metadata tag
     */
    public var name:String;
}
