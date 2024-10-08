// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract storeElement{
    //id of the element when a new element is created it takes an id
    //for every element I have an Id 

//id: identifier
//name: name of the  task
//initiator: Participant that send the message
//target: participant that receive the message 
//idInElement: element that point to this task
//idOutElement: pointed element 
//message: id of the message 
//executed: if the activity was executed 
    struct Activity{
        bytes32 id;
        bytes32 name;
        bytes32 initiator;
        bytes32 target;
        bytes32 idInElement;
        bytes32 idOutElement;
        bytes32 messageIn;//message of the initiator(sopra)
        bytes32 messageOut;//message of the target(sotto)
        bool executed;
    }
    mapping(bytes32=>Activity) public attivita;



    //key of the mappig goes into the Activity struct it represent 
    //one generic key for composition, different key for selection
    //the selcted address goes into the message
    mapping(bytes32=>address []) public participants;



//                       0    ,   1   ,  2    ,    3    ,    4    ,    5     ,     6         
    enum ElementType {START, EX_SPLIT, EX_JOIN, PAR_SPLIT, PAR_JOIN, EVENT_BASED, END}

    struct ControlFlowElement{
        bytes32 id;
        ElementType tipo;
        bytes32 [] incomingActivity;
        bytes32 [] outgoingActivity;
        bool executed;
    }
mapping(bytes32=>ControlFlowElement) public controlFlowElementList;
    

    //type to define one condition 
    enum ConditionType {GREATER,LESS,EQUAL,GREATEREQUAL,LESSEQUAL}
    //struct to represent the condition with the parameter of the condition
    struct EdgeCondition{
        bytes32 attribute;
        bytes32 comparisonValue;
        ConditionType condition;
        bytes32 idActivity;
    }


    //associate a key to the relative condition
    mapping(bytes32=>EdgeCondition[]) public edgeConditionMapping;

    struct Message{
        bytes32 id;
        bytes32 nome;
        bytes32 mappingKey;// key of attributes mapping
        bytes32 [] selectedAttr;//this field is used in the case of composition 
        address sourceParticipant;
        address targetParticipant;//maybe useless
        bytes32 idActivity;//It is used to see the activity associeted to the message from the message perspective
        bool executed;
    }
    mapping(bytes32=>Message)public messaggi;

//mapping to represent a message with its attribute 
//in the case of selection i have different key for different type of message
//in the case of composition I have a single key for all attributes than the selected attributes goes into the message struct
    mapping(bytes32 =>bytes32[]) public messageAttributes;





    //mappign attributes with its value
    mapping(bytes32=>bytes32) public attributiValue ;
    //struct used only to pass the participant information to the contract 
    struct PartecipantRoles{
        bytes32 key;
        address [] indirizzi;
    }   
    //struct used only to pass the message and the attributes to the contract
    struct MessageAttributes{
        bytes32 key;
        bytes32 [] attributes;
    }
    // When i create the contract i passed all the element in the choreography in the selection case i have almost all element populated 
    function setInformation(Activity [] memory allActivities,Message [] memory allMessages,PartecipantRoles[] memory participantList,
    MessageAttributes[] memory messagesAttributeList,ControlFlowElement[] memory allControlFlowElement,EdgeCondition[] memory edgeCondition) public{
        for (uint i=0;i<allActivities.length;i++){
            attivita[allActivities[i].id]=allActivities[i];
        }
        for (uint i=0;i<allMessages.length;i++){
            messaggi[allMessages[i].id]=allMessages[i];
        }
        for(uint i=0;i<participantList.length;i++){
            participants[participantList[i].key]=participantList[i].indirizzi;
        }
        for(uint i=0;i<messagesAttributeList.length;i++){
            messageAttributes[messagesAttributeList[i].key]=messagesAttributeList[i].attributes;
        }
        for(uint i=0;i<edgeCondition.length;i++){
            edgeConditionMapping[edgeCondition[i].idActivity].push(edgeCondition[i]);
        }
        for(uint i=0;i<allControlFlowElement.length;i++){
            controlFlowElementList[allControlFlowElement[i].id]=allControlFlowElement[i];
        }
    }

//function to set the activity in the composition case 
//for the selection case I already have all the data so it is useless
    function setCompActivity(Activity memory act) public {
        require(attivita[act.id].id==act.id);
        require(checkKeyParicipants(act.initiator));
        require(checkKeyParicipants(act.target));
        require(act.messageIn==messaggi[act.messageIn].id);
        require(act.messageOut==messaggi[act.messageOut].id);
        attivita[act.id]=act;
    }
    

//function to set the message in the composition case 
    function setCompMessage(Message memory _message) public {
        require(messaggi[_message.id].id==_message.id);
        require(checkKeyMessage(_message.mappingKey));
        require(_message.idActivity==attivita[_message.idActivity].id);
        require(checkAddressParticipants(attivita[_message.idActivity].initiator,_message.sourceParticipant));
        require(checkAddressParticipants(attivita[_message.idActivity].target,_message.targetParticipant));
    //check the attributed selected in the case of composition
        for(uint i=0;i<_message.selectedAttr.length;i++){
            require(checkAttribute(_message.mappingKey,_message.selectedAttr[i]));
        }
        messaggi[_message.id]=_message;
    }

//function to set the message in the selection case
    function setSelecMessage(bytes32 idMessage,bytes32 keyMapping, address source, address target,bytes32 idActivity)public{
        require(messaggi[idMessage].id==idMessage,"controllo id messaggio");
        require(attivita[idActivity].id==idActivity,"controllo id Attivita");
        require(checkKeyMessage(keyMapping),"controllo mapping");
        require(checkAddressParticipants(attivita[idActivity].initiator,source),"check sull'initiator");
        require(checkAddressParticipants(attivita[idActivity].target,target),"check sull'target");
        messaggi[idMessage].mappingKey=keyMapping;
        messaggi[idMessage].sourceParticipant=source;
        messaggi[idMessage].targetParticipant=target;
    }
//Per controllare se la chiave appartiene alla chiavi inserite in fase di generazione vado a controllare 
//se a quella chiave è inserito un almeno un indirizzo.
//check if the passed key has at least one element
    function checkKeyParicipants(bytes32 key)private view returns(bool){
        return participants[key].length>0;
    }

//funzione che mi controlla se un indirizzo è presente nella lista di indirizzo fornita all'inizio del generazione del contratto
//per togliere il for esterno potrei pensare di passare la key del mapping 
    function checkAddressParticipants(bytes32 key,address participant) private view returns(bool){
            address [] memory temp=participants[key];
            for (uint j=0;j<temp.length;j++){
                if(temp[j]==participant){
                    return true;
                }
            }
        return false;
    }


//controllo se per quel messaggio ci sono degli attributi inseriti 
//se non ci sono attributi significa che si cerca di utilizzare un messaggio inserito durante la fase di running 
    function checkKeyMessage(bytes32 key) private view returns(bool){
        return messageAttributes[key].length>0;
    }

//controllo se quell'attributo è presente in uno specifico mapping 
    function checkAttribute(bytes32 key,bytes32 attribute)private view returns(bool){
        bytes32 [] memory temp=messageAttributes[key];
        for (uint i=0;i<temp.length;i++){
            if(temp[i]==attribute){
                return true;
            }
        }
        return false;
    }

//Check if i can execute that message 
    function checkTheExecution(bytes32 idMessage) private returns (bool){
        require(!messaggi[idMessage].executed);
        Activity memory temp=attivita[messaggi[idMessage].idActivity];
        bool executed=false;
        //set the message executed to true
        if(temp.messageIn==idMessage && attivita[temp.idInElement].executed){
            messaggi[idMessage].executed=true;
            executed=true;
        }
        //set the message executed to true and the activity to true;
        if(temp.messageOut==idMessage && messaggi[temp.messageIn].executed){
            messaggi[idMessage].executed=true;
            attivita[messaggi[idMessage].idActivity].executed=true;
            executed=true;
        }
        //set the message executed to true and the gateway to true;
        //check if the gateway is stored on the gateway list
        if(controlFlowElementList[temp.idInElement].id==temp.idInElement){
            if(controlFlowElementList[temp.idInElement].tipo==ElementType.START){
                executed=true; 
                messaggi[idMessage].executed=true;
            }else if(checkForGatewayCondition(temp.idInElement,temp)){
                messaggi[idMessage].executed=true;
                controlFlowElementList[temp.idInElement].executed=true;
                executed=true;
            }
        }
        return executed;
    }
//Che the condition for different gateway
    function checkForGatewayCondition(bytes32 _idInElement,Activity memory currentActivity) view private returns(bool){
        //Check the condition for an split exclusie gateway
        //It have to controll the previous task and the condition on the edge 

        //TODO condizione false negli archi uscenti in modo da selezionare solo un attività che ha condizione true come nell'event 
        ControlFlowElement memory gateway=controlFlowElementList[_idInElement];
        if(gateway.tipo==ElementType.EX_SPLIT){
            //this is to check the previous task
            if(attivita[gateway.incomingActivity[0]].executed){
                //this is to check the condition on the edge
                if(checkEdgesCondition(currentActivity)){
                    return true;
                }
            }
            return false;
        }
        //check if the element is an exclusive gateway 
        if(gateway.tipo==ElementType.EX_JOIN){
            //the condition is that one of the previous task have to be executed
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(attivita[gateway.incomingActivity[i]].executed){
                    return true;
                }
            }
            return false;
        }
        //check if the element is a parallel split gateway
        //the only condition is that the previous task have to be executed
        if(gateway.tipo==ElementType.PAR_SPLIT){
            if(attivita[gateway.incomingActivity[0]].executed){
                return true;
            }
            return false;
        }
        //check if the element is a parallel join gateway
        //check if all the previous task are executed
        if(gateway.tipo==ElementType.PAR_JOIN){
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(!attivita[gateway.incomingActivity[i]].executed){
                    return false;
                }
            }
            return true;
        }

        //check if the element is a event based 
        //al the outgoing has to be not executed 
        if(gateway.tipo==ElementType.EVENT_BASED){
            if(attivita[gateway.incomingActivity[0]].executed){
                for(uint i=0;i<gateway.outgoingActivity.length;i++){
                    if(attivita[gateway.outgoingActivity[i]].executed){
                        return false;
                    }
                }
            }
            return true;
        }
        return false;
    }
//to check the condition It take in input the id of the in element of the gateway and the current activity 
    function checkEdgesCondition(Activity memory currentActivity) private view returns (bool){
        //get the edge from the gateway to the task where I execute the message
        EdgeCondition[] memory conditionType=edgeConditionMapping[currentActivity.id];
        for (uint i=0;i<conditionType.length;i++){
        //switch case to perform the controll of the attribute and a value
            if(conditionType[i].condition==ConditionType.GREATER){
                return greaterThan(conditionType[i].attribute,conditionType[i].comparisonValue);
            }
            if(conditionType[i].condition==ConditionType.LESS){
                return lessThan(conditionType[i].attribute,conditionType[i].comparisonValue);
            }
            if(conditionType[i].condition==ConditionType.EQUAL){
                return equal(conditionType[i].attribute,conditionType[i].comparisonValue);
            }
            if(conditionType[i].condition==ConditionType.GREATEREQUAL){
                return greaterThan(conditionType[i].attribute,conditionType[i].comparisonValue) || equal(conditionType[i].attribute,conditionType[i].comparisonValue);
            }
            if(conditionType[i].condition==ConditionType.LESSEQUAL){
                return lessThan(conditionType[i].attribute,conditionType[i].comparisonValue) || equal(conditionType[i].attribute,conditionType[i].comparisonValue);
            }
        }
        return false;
    }
//quando eseguo un messaggio eseguo questa funzione per assegnare un valore ai vari attributi 
    function insertIntoMap(bytes32 [] memory attributi, bytes32[] memory value) private {
        for(uint i=0;i<attributi.length;i++){
            attributiValue[attributi[i]]=value[i];
        }
    }
//execute the message in the selection case so 
//It has to insert the missing field only in the MessageStruct and It has to check for the execution
    function executeSelectMessage(bytes32 idActivity,bytes32 idMessage,bytes32 keyMapping, address source, address target,bytes32 [] memory attributi, bytes32[] memory value) public {
        setSelecMessage(idMessage, keyMapping, source, target, idActivity);
        require(checkTheExecution(idMessage),"errore nella validazione dell'esecuzione");

        insertIntoMap(attributi, value);
    }
//execute the message in the composition case
//It has to set all the information reguarding the activity all the information for the message and 
//It has to check for the execution
    function executeCompMessage(Activity memory _activity,Message memory _message,bytes32 [] memory attributi, bytes32[] memory value,ControlFlowElement memory _contolFlowElement,EdgeCondition[] memory someEdgeCondition) private {
        setCompActivity(_activity);
        setCompMessage(_message);
        setComControlFlowElement(_contolFlowElement,someEdgeCondition);
        checkTheExecution(_message.id);
        insertIntoMap(attributi, value);
    }
//how to check the control flow element if i can add it to during the execution ??
    function setComControlFlowElement(ControlFlowElement memory _controlFlowElement,EdgeCondition[] memory _someEdgeCondition)private {
        controlFlowElementList[_controlFlowElement.id]=_controlFlowElement;
        for(uint i=0;i<_someEdgeCondition.length;i++){
            edgeConditionMapping[_someEdgeCondition[i].idActivity].push(_someEdgeCondition[i]);
        }
    }

    function greaterThan(bytes32 attribute,bytes32 value)private view returns (bool){
        return attributiValue[attribute]>value;
    }

    function lessThan(bytes32 attribute,bytes32 value)private view returns (bool){
        return attributiValue[attribute]<value;
    }

    function equal(bytes32 attribute,bytes32 value)private view returns (bool){
        return attributiValue[attribute]==value;
    }
    function getAttivita(bytes32 id,
                        bytes32 name,
                        bytes32 initiator,
                        bytes32 target,
                        bytes32 idInElement,
                        bytes32 idOutElement,
                        bytes32 messageIn,
                        bytes32 messageOut,
                        bool executed)
    public pure returns(Activity  memory){
       
        return Activity(id,name,initiator,target,idInElement,idOutElement,messageIn,messageOut,executed);
    }
    function getMessage(bytes32 id,
                        bytes32 nome,
                        bytes32 mappingKey,
                        bytes32[] memory selectedAttr,
                        address sourceParticipant,
                        address targetParticipant,
                        bytes32 idActivity,
                        bool executed)
    public pure returns (Message memory){
        return Message(id,nome,mappingKey,selectedAttr,sourceParticipant,targetParticipant,idActivity,executed);
    }

    function getFlow(bytes32 id,ElementType tipo,bytes32 [] memory incomingActivity, bytes32[] memory outgoingActivity,bool executed)
    public pure returns (ControlFlowElement memory){
        return ControlFlowElement(id,tipo,incomingActivity,outgoingActivity,executed);
    }
    function intToBytes(uint256 n)public pure returns(bytes32){
        return bytes32(n);
    }
//attivita 1
//"0x000000000000000000000000000000000000000000000000000000000000000a","0x000000000000000000000000000000000000000000000000000000000000000a","0x00000000000000000000000000000000000000000000000000000000000003e8","0x00000000000000000000000000000000000000000000000000000000000007d0","0x0000000000000000000000000000000000000000000000000000000000000001","0x0000000000000000000000000000000000000000000000000000000000000014","0x0000000000000000000000000000000000000000000000000000000000000064","0x00000000000000000000000000000000000000000000000000000000000000c8","false"

//attivita 2
//"0x0000000000000000000000000000000000000000000000000000000000000014","0x0000000000000000000000000000000000000000000000000000000000000014","0x00000000000000000000000000000000000000000000000000000000000007d0","0x0000000000000000000000000000000000000000000000000000000000000bb8","0x000000000000000000000000000000000000000000000000000000000000000a","0x0000000000000000000000000000000000000000000000000000000000000002","0x000000000000000000000000000000000000000000000000000000000000012c","0x0000000000000000000000000000000000000000000000000000000000000190",false


/*
[
["0x000000000000000000000000000000000000000000000000000000000000000a","0x000000000000000000000000000000000000000000000000000000000000000a","0x00000000000000000000000000000000000000000000000000000000000003e8","0x00000000000000000000000000000000000000000000000000000000000007d0","0x0000000000000000000000000000000000000000000000000000000000000001","0x0000000000000000000000000000000000000000000000000000000000000014","0x0000000000000000000000000000000000000000000000000000000000000064","0x00000000000000000000000000000000000000000000000000000000000000c8",false],
["0x0000000000000000000000000000000000000000000000000000000000000014","0x0000000000000000000000000000000000000000000000000000000000000014","0x00000000000000000000000000000000000000000000000000000000000007d0","0x0000000000000000000000000000000000000000000000000000000000000bb8","0x000000000000000000000000000000000000000000000000000000000000000a","0x0000000000000000000000000000000000000000000000000000000000000002","0x000000000000000000000000000000000000000000000000000000000000012c","0x0000000000000000000000000000000000000000000000000000000000000190",false]
]
*/
//start 
//"0x0000000000000000000000000000000000000000000000000000000000000001",0,[],"0x000000000000000000000000000000000000000000000000000000000000000a",false

//Messaggio 1 
//"0x0000000000000000000000000000000000000000000000000000000000000064","0x0000000000000000000000000000000000000000000000000000000000000064","0x0000000000000000000000000000000000000000000000000000000000000013",[],"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x000000000000000000000000000000000000000000000000000000000000000a",false

//Messaggio 2
//"0x00000000000000000000000000000000000000000000000000000000000000c8","0x00000000000000000000000000000000000000000000000000000000000000c8","0x000000000000000000000000000000000000000000000000000000000000001d",[],"0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x000000000000000000000000000000000000000000000000000000000000000a",false

/*
[
["0x0000000000000000000000000000000000000000000000000000000000000064","0x0000000000000000000000000000000000000000000000000000000000000064","0x0000000000000000000000000000000000000000000000000000000000000013",[],"0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x000000000000000000000000000000000000000000000000000000000000000a",false],
["0x00000000000000000000000000000000000000000000000000000000000000c8","0x00000000000000000000000000000000000000000000000000000000000000c8","0x000000000000000000000000000000000000000000000000000000000000001d",[],"0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000","0x000000000000000000000000000000000000000000000000000000000000000a",false]
]
*/
//Messaggio 3
//0x000000000000000000000000000000000000000000000000000000000000012c,0x000000000000000000000000000000000000000000000000000000000000012c,0x0000000000000000000000000000000000000000000000000000000000000027,,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x0000000000000000000000000000000000000000000000000000000000000014,false

//Messaggio 4
//0x0000000000000000000000000000000000000000000000000000000000000190,0x0000000000000000000000000000000000000000000000000000000000000190,0x0000000000000000000000000000000000000000000000000000000000000031,,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0x0000000000000000000000000000000000000000000000000000000000000014,false

//Participant
/*
[
["0x00000000000000000000000000000000000000000000000000000000000003e8",["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]],
["0x00000000000000000000000000000000000000000000000000000000000007d0",["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]],
["0x0000000000000000000000000000000000000000000000000000000000000bb8",["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]],
["0x0000000000000000000000000000000000000000000000000000000000000fa0",["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4"]]
]
*/


//MessageAttribute List
/*
[
["0x0000000000000000000000000000000000000000000000000000000000000013",["0x000000000000000000000000000000000000000000000000000000000000003b"]],
["0x000000000000000000000000000000000000000000000000000000000000001d",["0x0000000000000000000000000000000000000000000000000000000000000045"]],
["0x0000000000000000000000000000000000000000000000000000000000000027",["0x000000000000000000000000000000000000000000000000000000000000004f"]],
["0x0000000000000000000000000000000000000000000000000000000000000031",["0x0000000000000000000000000000000000000000000000000000000000000059"]]
]
*/

//ControlFlow
/*
[
["0x0000000000000000000000000000000000000000000000000000000000000001",0,[],["0x000000000000000000000000000000000000000000000000000000000000000a"],true],
["0x0000000000000000000000000000000000000000000000000000000000000002",6,["0x0000000000000000000000000000000000000000000000000000000000000014"],[],false]
]
*/

//Esecuzione di un messaggio M1
/*
0x000000000000000000000000000000000000000000000000000000000000000a
0x0000000000000000000000000000000000000000000000000000000000000064
0x0000000000000000000000000000000000000000000000000000000000000013
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
["0x000000000000000000000000000000000000000000000000000000000000003b"]
["0x0000000000000000000000000000000000000000000000000000000000000001"]
*/

//Esecuzione messaggio M2
/*
0x000000000000000000000000000000000000000000000000000000000000000a
0x00000000000000000000000000000000000000000000000000000000000000c8
0x000000000000000000000000000000000000000000000000000000000000001d
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
["0x0000000000000000000000000000000000000000000000000000000000000045"]
["0x000000000000000000000000000000000000000000000000000000000000004e"]
*/
}