import { saveFeedback, retrieveLastTrial } from "./db";

// Audio Context for sound generation
const audioContext = new (window.AudioContext || window.webkitAudioContext)();

// Game configurations
const games = [
    {
        name: "High-Low Alternating Pattern",
        patternLength: 10,
        target: [9, 0, 8, 1, 7, 2, 6, 3, 5, 4],

        checkSequence(sequence) {
            for (let i = 0; i < sequence.length; i++) {
                if (sequence[i] !== this.target[i]) 
                    return false;
            }
            return true;
        },
        checkPress(number, sequence) {
            return number === this.target[sequence.length];
        },
        checkComplete(sequence) {

            if (sequence.length !== this.target.length) 
                return false;

            for (let i = 0; i < this.target.length; i++) {
                if (sequence[i] !== this.target[i]) 
                    return false;
            }

            return true;
        }
    }
];

let currentGame = 0;
let currentSequence = [];
let timerInterval;
let timeRemaining = 600;
let conditionType = '';
let participantName = "";
let participantNumber = 0;
let gameResults = [];
let totalClicks = 0;
let correctClicks = 0;
let incorrectClicks = 0;

const soundDuration = 0.25;

function playCorrectSound() {
    // Pleasant "ding" sound
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.value = 880;
    oscillator.type = 'sine';
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.2);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + soundDuration);
}

function playIncorrectSound() {
    // Harsh buzzer sound
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.frequency.value = 150;
    oscillator.type = 'sawtooth';
    
    gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.4);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + soundDuration);
}

async function startExperiment() {
    participantName = document.getElementById('participantName').value;

    if (!participantName) {
        alert("Please enter your name");
        return;
    }

    const data = await retrieveLastTrial();
    participantNumber = data !== null ? data.participantNumber + 1 : 0;
    conditionType = participantNumber % 2 === 0 ? 'A' : 'B';
    
    if (!conditionType) return;

    document.querySelector('.setup-screen').classList.remove('active');
    document.querySelector('.experiment-screen').classList.add('active');
    
    startGame();
}

window.startExperiment = startExperiment;

function startGame() {
    currentSequence = [];
    totalClicks = 0;
    timeRemaining = 600;
    updateTimer();
    
    const gameNumberElement = document.getElementById('gameNumber');
    gameNumberElement.textContent = currentGame + 1;
    console.log('Starting game:', currentGame + 1);
    
    // Create pattern display with blanks
    updatePatternDisplay();
    
    // Create button grid with 10 buttons
    const grid = document.getElementById('buttonGrid');
    const keypad = [1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0, null];
    grid.innerHTML = '';
    
    keypad.forEach((num) => {
        if (num === null) {
            const space = document.createElement('div');
            grid.appendChild(space);
            return;
        }

        const button = document.createElement('button');
        button.className = "number-button";
        button.textContent = num;
        button.addEventListener('click', () => handleButtonClick(num, button));
        grid.appendChild(button);
    });

    // Start timer
    timerInterval = setInterval(() => {
        timeRemaining--;
        updateTimer();
        
        if (timeRemaining <= 0) {
            endGame();
        }
    }, 1000);
}

function updatePatternDisplay() {
    const display = document.getElementById('patternDisplay');
    const patternLength = games[currentGame].patternLength;
    
    display.innerHTML = '';
    
    for (let i = 0; i < patternLength; i++) {
        const slot = document.createElement('div');
        slot.className = 'pattern-slot';
        
        if (i < currentSequence.length) {
            slot.textContent = currentSequence[i];
            slot.classList.add('filled');
        } else {
            slot.textContent = '_';
        }
        
        display.appendChild(slot);
    }
}

function handleButtonClick(number, buttonElement) {
    totalClicks++;
    
    const isCorrect = games[currentGame].checkPress(number, currentSequence);
    currentSequence.push(number);
    
    // visual and audio feedback based on condition type
    buttonElement.classList.remove('correct', 'incorrect');
    
    if (conditionType === 'A') {
        // Type A: positive reinforcement for correct presses
        if (isCorrect) {
            buttonElement.classList.add('correct');
            playCorrectSound();
            correctClicks++;
        } else {
            incorrectClicks++;
        }
    } else if (conditionType === 'B') {
        // Type B: negative reinforcement for incorrect presses
        if (!isCorrect) {
            buttonElement.classList.add('incorrect');
            playIncorrectSound();
            incorrectClicks++;
        } else {
            correctClicks++;
        }
    }
    
    updatePatternDisplay();
    
    // Checking if pattern is complete
    if (currentSequence.length === games[currentGame].patternLength) {
        const patternIsCorrect = games[currentGame].checkComplete(currentSequence);
        
        if (patternIsCorrect) {
            console.log('Correct pattern completed');
            
            setTimeout(() => {
                endGame();
            }, 1000);
        } else {
            // Pattern was wrong, reset for retry
            setTimeout(() => {
                currentSequence = [];
                updatePatternDisplay();
            }, 500);
        }
    }
    
    // Reset button color after animation
    setTimeout(() => {
        buttonElement.classList.remove('correct', 'incorrect');
    }, 300);
}

function updateTimer() {
    const minutes = Math.floor(timeRemaining / 60);
    const seconds = timeRemaining % 60;
    document.getElementById('timer').textContent = 
        `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

function endGame() {
    clearInterval(timerInterval);
    
    console.log('Ending game:', currentGame + 1, 'Total clicks:', totalClicks);
    
    // Record results
    const totalElapsedTime = 600 - timeRemaining;
    const thinkingTime = (conditionType === 'A' ? totalElapsedTime - soundDuration * correctClicks : totalElapsedTime - soundDuration * incorrectClicks);

    gameResults.push({
        game: games[currentGame].name,
        totalClicks: totalClicks,
        correctClicks: correctClicks,
        incorrectClicks: incorrectClicks,
        totalElapsedTime: totalElapsedTime,
        thinkingTime: thinkingTime
    });

    const trialData = {
        participantName: participantName,
        participantNumber: participantNumber, 
        feedbackType: conditionType === 'A' ? "POSITIVE" : "NEGATIVE",
        numberCorrect: correctClicks,
        numberIncorrect: incorrectClicks,
        totalClicks: totalClicks,
        totalElapsedTime: totalElapsedTime,
        thinkingTime: thinkingTime
    }
    console.log("Trial Data: ", trialData);
    saveFeedback(trialData)    
    
    currentGame++;
    console.log('Moving to game:', currentGame + 1);
    
    if (currentGame < games.length) {
        // Start next game
        setTimeout(() => {
            startGame();
        }, 1000);
    } else {
        // Show results
        console.log('All games complete');
        showResults();
    }
}

function showResults() {
    document.querySelector('.experiment-screen').classList.remove('active');
    document.querySelector('.complete-screen').classList.add('active');
    
    const resultsDiv = document.getElementById('results');
    resultsDiv.innerHTML = `
        <h2 style="text-align: center;">Results</h2>
        <br>

        <div class="result-item">
            <h3>Participant Information</h3>
            <p><strong>Participant Name:</strong> ${participantName}</p>
            <p><strong>Participant Number:</strong> ${participantNumber}</p>
            <p><strong>Condition:</strong> Type ${conditionType} 
                ${conditionType === 'A' ? '(Positive Feedback - Correct Presses)' : '(Negative Feedback - Incorrect Presses)'}
            </p>
            <span class="condition-badge">Type ${conditionType}</span>
        </div>
    `;
    
    gameResults.forEach((result, index) => {
        resultsDiv.innerHTML += `
            <div class="result-item">
                <h3>Game ${index + 1}: ${result.game}</h3>
                <p><strong>Correct Clicks: </strong> ${result.correctClicks}</p>
                <p><strong>Incorrect Clicks: </strong> ${result.incorrectClicks}</p>
                <p><strong>Total Button Clicks:</strong> ${result.totalClicks}</p>
                <br>
                <p><strong>Total Elapsed Time:</strong> ${result.totalElapsedTime} seconds</p>
                <p><strong>Thinking Time:</strong> ${result.thinkingTime} seconds</p>
            </div>
        `;
    });

    resultsDiv.innerHTML += `
        <div class="survey-section" style="display: flex; flex-direction: column; align-items: center; justify-content: center;">
            <h2 style="text-align: center;">Post-Experiment Study Survey</h2>
            <br>
            <p style="text-align: center; max-width=100%">Please complete the Google Form below. We will use your response for a study that we are conducting.</p>
            <br>
            <iframe
                src="https://forms.gle/tATyGLhL6Z94ugho6"
                width="100%"
                height="700"
                frameborder="0"
                marginheight="0"
                marginwidth="0"
                style="display: block; margin: 0 auto;">
                Loading...
            </iframe>
        </div>
    `;
}