// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract contractMemory{


    struct Instance{
        mapping(bytes32=>Activity) attivita;
        mapping(bytes32=>address []) participants;
        mapping(bytes32=>ControlFlowElement) controlFlowElementList;
        mapping(bytes32=>EdgeCondition[]) edgeConditionMapping;
        mapping(bytes32=>Message) messaggi;
        mapping(bytes32 =>bytes32[]) messageAttributes;
        mapping(bytes32=>bytes32) attributiValue ;
    }

    mapping(bytes32=>bytes32[]) choInstanceList;

    mapping(bytes32=>Instance) istancies;   
       
    event functionDone(string);
    //id of the element when a new element is created it takes an id
    //for every element I have an Id 
    function attivita(bytes32 hashIdInstance,bytes32 idActivity)public view returns(Activity memory){
        return istancies[hashIdInstance].attivita[idActivity];
    }
    function messaggi(bytes32 hashIdInstance,bytes32 idMessagge)public view returns(Message memory){
        return istancies[hashIdInstance].messaggi[idMessagge];
    }
    function controlFlowElementList(bytes32 hashIdInstance,bytes32 idControlFlowElement)public view returns(ControlFlowElement memory){
        return istancies[hashIdInstance].controlFlowElementList[idControlFlowElement];
    }
//id: identifier
//name: name of the  task
//initiator: Participant that send the message
//target: participant that receive the message 
//idInElement: element that point to this task
//idOutElement: pointed element 
//message: id of the message 
//executed: if the activity was executed 
    struct Activity{
        bool executed;
        bytes32 id;
        bytes32 idInElement;
        bytes32 idOutElement;
        bytes32 initiator;
        bytes32 messageIn;//message of the initiator(sopra)
        bytes32 messageOut;//message of the target(sotto)
        bytes32 name;
        bytes32 target;
        bool tempState;
    }

    //key of the mappig goes into the Activity struct it represent 
    //one generic key for composition, different key for selection
    //the selcted address goes into the message

//                       0    ,   1   ,  2    ,    3    ,    4    ,    5     ,     6    7     
    enum ElementType {START, EX_SPLIT, EX_JOIN, PAR_SPLIT, PAR_JOIN, EVENT_BASED, END,TEMP}
    struct ControlFlowElement{
        bool executed;
        bytes32 id;
        bytes32 [] incomingActivity;
        bytes32 [] outgoingActivity;
        ElementType tipo;
    }

    //type to define one condition 
    //                      0,    1,   2,      3,         4
    enum ConditionType {GREATER,LESS,EQUAL,GREATEREQUAL,LESSEQUAL}
    //struct to represent the condition with the parameter of the condition
    struct EdgeCondition{
        bytes32 attribute;
        bytes32 comparisonValue;
        ConditionType condition;
        bytes32 idActivity;
    }
    //associate a key to the relative condition

    struct Message{
        bool executed;
        bytes32 id;
        bytes32 idActivity;//It is used to see the activity associeted to the message from the message perspective
        bytes32 mappingKey;// key of attributes mapping
        bytes32 name;
        bytes32 [] selectedAttr;//this field is used in the case of composition 
        address sourceParticipant;
        address targetParticipant;//maybe useless
        bool tempState;
    }


//mapping to represent a message with its attribute 
//in the case of selection i have different key for different type of message
//in the case of composition I have a single key for all attributes than the selected attributes goes into the message struct
    //mappign attributes with its value

    //struct used only to pass the participant information to the contract 
    struct PartecipantRoles{
        address [] addr;
        bytes32 keyMapping;
    }   
    //struct used only to pass the message and the attributes to the contract
    struct MessageAttributes{
        bytes32 [] attributes;
        bytes32 keyMapping;
    }

    event FunctionDone (bytes32 messaggeId);
    // When i create the contract i passed all the element in the choreography in the selection case i have almost all element populated 
    function setInformation(Activity [] memory allActivities,Message [] memory allMessages,PartecipantRoles[] memory participantList,
    MessageAttributes[] memory messagesAttributeList,ControlFlowElement[] memory allControlFlowElement,EdgeCondition[] memory edgeCondition,
    bytes32 idInstance,bytes32 hashIdInstance) public{

        for (uint i=0;i<allActivities.length;i++){
            istancies[hashIdInstance].attivita[allActivities[i].id]=allActivities[i];
        }
        for (uint i=0;i<allMessages.length;i++){
            istancies[hashIdInstance].messaggi[allMessages[i].id]=allMessages[i];
        }
        for(uint i=0;i<participantList.length;i++){
            istancies[hashIdInstance].participants[participantList[i].keyMapping]=participantList[i].addr;
        }
        for(uint i=0;i<messagesAttributeList.length;i++){
            istancies[hashIdInstance].messageAttributes[messagesAttributeList[i].keyMapping]=messagesAttributeList[i].attributes;
        }
        for(uint i=0;i<edgeCondition.length;i++){
            istancies[hashIdInstance].edgeConditionMapping[edgeCondition[i].idActivity].push(edgeCondition[i]);
        }
        for(uint i=0;i<allControlFlowElement.length;i++){
            istancies[hashIdInstance].controlFlowElementList[allControlFlowElement[i].id]=allControlFlowElement[i];
        }

        choInstanceList[idInstance].push(hashIdInstance);
        emit functionDone("Resources Loaded");
    }
    
}