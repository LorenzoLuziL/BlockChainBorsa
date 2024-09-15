// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract storeElement{
    event functionDone(string);
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
        bool executed;
        bytes32 id;
        bytes32 idInElement;
        bytes32 idOutElement;
        bytes32 initiator;
        bytes32 messageIn;//message of the initiator(sopra)
        bytes32 messageOut;//message of the target(sotto)
        bytes32 name;
        bytes32 target;
    }
    mapping(bytes32=>Activity) public attivita;
    //key of the mappig goes into the Activity struct it represent 
    //one generic key for composition, different key for selection
    //the selcted address goes into the message
    mapping(bytes32=>address []) public participants;
//                       0    ,   1   ,  2    ,    3    ,    4    ,    5     ,     6    7     
    enum ElementType {START, EX_SPLIT, EX_JOIN, PAR_SPLIT, PAR_JOIN, EVENT_BASED, END,TEMP}
    struct ControlFlowElement{
        bool executed;
        bytes32 id;
        bytes32 [] incomingActivity;
        bytes32 [] outgoingActivity;
        ElementType tipo;
    }
mapping(bytes32=>ControlFlowElement) public controlFlowElementList;
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
    mapping(bytes32=>EdgeCondition[]) public edgeConditionMapping;
    struct Message{
        bool executed;
        bytes32 id;
        bytes32 idActivity;//It is used to see the activity associeted to the message from the message perspective
        bytes32 mappingKey;// key of attributes mapping
        bytes32 name;
        bytes32 [] selectedAttr;//this field is used in the case of composition 
        address sourceParticipant;
        address targetParticipant;//maybe useless
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
    MessageAttributes[] memory messagesAttributeList,ControlFlowElement[] memory allControlFlowElement,EdgeCondition[] memory edgeCondition) public{
        for (uint i=0;i<allActivities.length;i++){
            attivita[allActivities[i].id]=allActivities[i];
        }
        for (uint i=0;i<allMessages.length;i++){
            messaggi[allMessages[i].id]=allMessages[i];
        }
        for(uint i=0;i<participantList.length;i++){
            participants[participantList[i].keyMapping]=participantList[i].addr;
        }
        for(uint i=0;i<messagesAttributeList.length;i++){
            messageAttributes[messagesAttributeList[i].keyMapping]=messagesAttributeList[i].attributes;
        }
        for(uint i=0;i<edgeCondition.length;i++){
            edgeConditionMapping[edgeCondition[i].idActivity].push(edgeCondition[i]);
        }
        for(uint i=0;i<allControlFlowElement.length;i++){
            controlFlowElementList[allControlFlowElement[i].id]=allControlFlowElement[i];
        }
        emit functionDone("Resources Loaded");
    }

//function to set the activity in the composition case 
//for the selection case I already have all the data so it is useless
    function setCompActivity(Activity memory act) public {
        require(attivita[act.id].id==act.id,"id Activity");
        require(checkKeyParicipants(act.initiator),"key initiator");
        require(checkKeyParicipants(act.target),"key target");
        require(act.messageIn==messaggi[act.messageIn].id,"message in");
        require(act.messageOut==messaggi[act.messageOut].id,"message out");
        attivita[act.id]=act;
    }
    

//function to set the message in the composition case 
    function setCompMessage(Message memory _message) public {
        require(messaggi[_message.id].id==_message.id,"id message");
        require(checkKeyMessage(_message.mappingKey),"key mapping");
        require(_message.idActivity==attivita[_message.idActivity].id,"id activity message");
        require(checkAddressParticipants(attivita[_message.idActivity].initiator,_message.sourceParticipant),"address initiator");
        require(checkAddressParticipants(attivita[_message.idActivity].target,_message.targetParticipant),"address target");
    //check the attributed selected in the case of composition
        for(uint i=0;i<_message.selectedAttr.length;i++){
            require(checkAttribute(_message.mappingKey,_message.selectedAttr[i]),"attribute");
        }
        require(!messaggi[_message.id].executed,"already executed");
        messaggi[_message.id]=_message;
    }

//function to set the message in the selection case
   /* function setSelecMessage(bytes32 idMessage,bytes32 keyMapping, address source, address target,bytes32 idActivity)public{
        require(messaggi[idMessage].id==idMessage,"controllo id messaggio");
        require(attivita[idActivity].id==idActivity,"controllo id Attivita");
        require(checkKeyMessage(keyMapping),"controllo mapping");
        require(checkAddressParticipants(attivita[idActivity].initiator,source),"check sull'initiator");
        require(checkAddressParticipants(attivita[idActivity].target,target),"check sull'target");
        require(!messaggi[idMessage].executed,"already executed");
        messaggi[idMessage].mappingKey=keyMapping;
        messaggi[idMessage].sourceParticipant=source;
        messaggi[idMessage].targetParticipant=target;
    }*/
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

    function getListParticipant(bytes32 key)public view returns (address[] memory){
        return participants[key];
    }

//controllo se per quel messaggio ci sono degli attributi inseriti 
//se non ci sono attributi significa che si cerca di utilizzare un messaggio inserito durante la fase di running 
    function checkKeyMessage(bytes32 key) public view returns(bool){
        return messageAttributes[key].length>0;
    }
    function getListAttributeForKey(bytes32 key)public view returns(bytes32[] memory){
        return messageAttributes[key];
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
        Activity memory temp=attivita[messaggi[idMessage].idActivity];
        //set the message executed to true
        if(temp.messageIn==idMessage){
            if(attivita[temp.idInElement].executed){
                messaggi[idMessage].executed=true;
                if(attivita[temp.id].messageOut==bytes32(0)){
                    attivita[temp.id].executed=true;
                }
                return true;
            }else if (controlFlowElementList[temp.idInElement].id==temp.idInElement){
                if(controlFlowElementList[temp.idInElement].tipo==ElementType.START){
                    messaggi[idMessage].executed=true;
                    if(attivita[temp.id].messageOut==bytes32(0)){
                        attivita[temp.id].executed=true;
                    }
                    return true; 
                }else if(controlFlowElementList[temp.idInElement].executed && checkForGatewayCondition(temp.idInElement,temp.id)){
                    messaggi[idMessage].executed=true;
                    if(attivita[temp.id].messageOut==bytes32(0)){
                        attivita[temp.id].executed=true;
                    }
                    return true;
                }
            }
        }
        //set the message executed to true and the activity to true;
        if(temp.messageOut==idMessage && messaggi[temp.messageIn].executed){
            messaggi[idMessage].executed=true;
            attivita[messaggi[idMessage].idActivity].executed=true;
            return true;
        }
        return false;
    }

function setActivityToFalse(bytes32 idActivity) private {
        attivita[idActivity].executed=false;
        messaggi[attivita[idActivity].messageIn].executed=false;
        if(messaggi[attivita[idActivity].messageOut].id!=bytes32(0)){
            messaggi[attivita[idActivity].messageOut].executed=false;
        }
}
function checkNextElement(bytes32 idElement) private {
    // Check if the element is an activity
    if (attivita[idElement].id != bytes32(0)) {
        setActivityToFalse(idElement);
        return;
    }
    // Check if the element is a control flow element and not yet executed
    //ControlFlowElement storage element = controlFlowElementList[idElement];
    if (controlFlowElementList[idElement].id != bytes32(0) ) {
        // Evaluate the gateway condition and update execution status
        controlFlowElementList[idElement].executed = checkForNextGatewayCondition(idElement);

        // Update the outgoing activities based on the execution status
        if(checkForNextGatewayCondition(idElement) && controlFlowElementList[idElement].tipo!=ElementType.EX_SPLIT ){
            for (uint i = 0; i < controlFlowElementList[idElement].outgoingActivity.length; i++) {
                checkNextElement(controlFlowElementList[idElement].outgoingActivity[i]);
               // bytes32 outgoingId = controlFlowElementList[idElement].outgoingActivity[i];
                //controlFlowElementList[outgoingId].executed = checkForNextGatewayCondition(outgoingId);
            }
        }
       
        return;
    }
    // Default case: set the current element and its outgoing activities to false
    for (uint i = 0; i < controlFlowElementList[idElement].outgoingActivity.length; i++) {
        checkNextElement(controlFlowElementList[idElement].outgoingActivity[i]);
    }
}

function checkForNextGatewayCondition(bytes32 _idInElement) private returns (bool) {
    ControlFlowElement storage gateway = controlFlowElementList[_idInElement];

    // Handle the simple cases first: EX_JOIN, PAR_SPLIT, EVENT_BASED
    if (
        gateway.tipo == ElementType.EX_JOIN || 
        gateway.tipo == ElementType.PAR_SPLIT || 
        gateway.tipo == ElementType.EVENT_BASED ||
        gateway.tipo == ElementType.TEMP || gateway.tipo == ElementType.END 
    ){
        return true;
    }
    // Handle EX_SPLIT
    if (gateway.tipo == ElementType.EX_SPLIT) {
        for (uint i = 0; i < gateway.outgoingActivity.length; i++) {
            bytes32 outgoingId = gateway.outgoingActivity[i];
            if (controlFlowElementList[outgoingId].id != bytes32(0)) {
                controlFlowElementList[outgoingId].executed = checkEdgesConditionOnlyId(outgoingId);
            }
        }
        return true;
    }

    // Handle PAR_JOIN
    if (gateway.tipo == ElementType.PAR_JOIN) {
        for (uint i = 0; i < gateway.incomingActivity.length; i++) {
            bytes32 incomingId = gateway.incomingActivity[i];
            if (attivita[incomingId].id != bytes32(0) && !attivita[incomingId].executed) {
                return false;
            }
        }
        return true;
    }

    return false;
}

//Che the condition for different gateway
    function checkForGatewayCondition(bytes32 _idInElement,bytes32 currentActivity) private view returns(bool){
        //Check the condition for an split exclusie gateway
        //It have to controll the previous task and the condition on the edge 
        ControlFlowElement memory gateway=controlFlowElementList[_idInElement];
        if(gateway.tipo==ElementType.EX_SPLIT && gateway.executed){
            //this is to check the previous task
            if(attivita[gateway.incomingActivity[0]].id!=bytes32(0)){
                if(attivita[gateway.incomingActivity[0]].executed){
                    //this is to check the condition on the edge
                    for(uint i=0;i<gateway.outgoingActivity.length;i++){
                        if(attivita[gateway.outgoingActivity[i]].executed){
                            return false;
                        }
                    }
                    if(checkEdgesConditionOnlyId(currentActivity)){
                        return true;
                    }
                }
                return false; 
            }
        }
        //check if the element is an exclusive gateway 
        if(gateway.tipo==ElementType.EX_JOIN && gateway.executed){
            //the condition is that one of the previous task have to be executed
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(attivita[gateway.incomingActivity[i]].id==gateway.incomingActivity[i]){
                    if(attivita[gateway.incomingActivity[i]].executed){
                        return true;
                    }
                }
                
            }
            return false;
        }
        //check if the element is a parallel split gateway
        //the only condition is that the previous task have to be executed
        if(gateway.tipo==ElementType.PAR_SPLIT && gateway.executed){
            if(attivita[gateway.incomingActivity[0]].id!=bytes32(0) && attivita[gateway.incomingActivity[0]].executed){
                return true;
            }else if(controlFlowElementList[gateway.incomingActivity[0]].id!=bytes32(0) && controlFlowElementList[gateway.incomingActivity[0]].executed){
                return true;
            }
            return false;
        }
        //check if the element is a parallel join gateway
        //check if all the previous task are executed
        if(gateway.tipo==ElementType.PAR_JOIN && gateway.executed){
            for(uint i=0;i<gateway.incomingActivity.length;i++){
                if(attivita[gateway.incomingActivity[i]].id!=bytes32(0)){
                    if(!attivita[gateway.incomingActivity[i]].executed){
                        return false;
                    }
                }
            }
            return true;
        }

        //check if the element is a event based 
        //al the outgoing has to be not executed 
        if(gateway.tipo==ElementType.EVENT_BASED && gateway.executed){
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



    function checkEdgesConditionOnlyId(bytes32 currentActivity) private view returns (bool){
        //get the edge from the gateway to the task where I execute the message
        EdgeCondition[] memory conditionType=edgeConditionMapping[currentActivity];
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
  /*  function executeSelectMessage(bytes32 [] memory attributi,bytes32 idActivity,bytes32 idMessage,bytes32 keyMapping, address source, address target, bytes32[] memory value) public {
        setSelecMessage(idMessage, keyMapping, source, target, idActivity);
        require(checkTheExecution(idMessage),"errore nella validazione dell'esecuzione");
        Activity memory temp=attivita[idActivity];
        insertIntoMap(attributi, value);
        if(temp.messageIn==idMessage && temp.messageOut==bytes32(0)){
            checkNextElement(temp.idOutElement);
        }else if(temp.messageOut==idMessage){
            checkNextElement(temp.idOutElement);
        }
         emit functionDone("Messagge executed");
    }*/
//execute the message in the composition case
//It has to set all the information reguarding the activity all the information for the message and 
//It has to check for the execution
    function executeCompMessage(Activity memory _activity,Message memory _message,bytes32 [] memory attributi, bytes32[] memory value,ControlFlowElement[] memory _contolFlowElement,EdgeCondition[] memory someEdgeCondition) public {
        setCompActivity(_activity);
        setCompMessage(_message);
        setComControlFlowElement(_contolFlowElement,someEdgeCondition);
        require(checkTheExecution(_message.id),"errore nella validazione dell'esecuzione");
        Activity memory temp=attivita[_activity.id];
        insertIntoMap(attributi, value);
        if(temp.messageIn==_message.id && temp.messageOut==bytes32(0)){
            checkNextElement(temp.idOutElement);
        }else if(temp.messageOut==_message.id){
            checkNextElement(temp.idOutElement);
        }
        emit functionDone("Messagge executed");
    }
//how to check the control flow element if i can add it to during the execution ??
    function setComControlFlowElement(ControlFlowElement[] memory _controlFlowElement,EdgeCondition[] memory _someEdgeCondition)private {
        for(uint i=0;i<_controlFlowElement.length;i++){
            controlFlowElementList[_controlFlowElement[i].id]=_controlFlowElement[i];
        }
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
}