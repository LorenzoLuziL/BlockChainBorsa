// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./contractMemory.sol";
contract contractLogic is contractMemory{

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
    function checkKeyMessage(bytes32 key) public view returns(bool){
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
                    controlFlowElementList[temp.idInElement].executed=true;
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
        attivita[idActivity].tempState=true;
        messaggi[attivita[idActivity].messageIn].executed=false;
        messaggi[attivita[idActivity].messageIn].tempState=true;
        if(messaggi[attivita[idActivity].messageOut].id!=bytes32(0)){
            messaggi[attivita[idActivity].messageOut].executed=false;
            messaggi[attivita[idActivity].messageOut].tempState=true;
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
                if(checkEdgesConditionOnlyId(outgoingId)){
                    checkNextElement(outgoingId);
                }
            }
            if(attivita[outgoingId].id !=bytes32(0) && checkEdgesConditionOnlyId(outgoingId)){
                setActivityToFalse(outgoingId);
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
    function checkForGatewayCondition(bytes32 _idInElement,bytes32 currentActivity) private  returns(bool){
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
            if(attivita[gateway.incomingActivity[0]].executed || controlFlowElementList[gateway.incomingActivity[0]].executed){
                for(uint i=0;i<gateway.outgoingActivity.length;i++){
                    if(attivita[gateway.outgoingActivity[i]].executed){
                        return false;
                    }else{
                        attivita[gateway.outgoingActivity[i]].executed=false;
                        attivita[gateway.outgoingActivity[i]].tempState=false;
                        messaggi[attivita[gateway.outgoingActivity[i]].messageIn].executed=false;
                        messaggi[attivita[gateway.outgoingActivity[i]].messageIn].tempState=false;
                        if(messaggi[attivita[gateway.outgoingActivity[i]].messageOut].id!=bytes32(0)){
                            messaggi[attivita[gateway.outgoingActivity[i]].messageOut].executed=false;
                            messaggi[attivita[gateway.outgoingActivity[i]].messageOut].tempState=false;
                        }
                    }
                }
                return true;
            }
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