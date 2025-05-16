// hooks.js - LiveView hooks for the Lora application

const Hooks = {
  TrickWinnerDelay: {
    mounted() {
      // Track trick completion state
      this.lastTrickCount = 0;
      this.trickWinnerVisible = false;
      
      // Start tracking trick changes
      this.handleTrickChanges();
    },
    
    handleTrickChanges() {
      // Use a timer to periodically check the trick state
      this.timer = setInterval(() => {
        // Count cards in the trick
        const trickCards = document.querySelectorAll('[id^="trick-card-"]');
        const currentTrickCount = trickCards.length;
        
        // Find winner elements
        const winnerCard = document.querySelector('.winner-card');
        const winnerHighlight = document.querySelector('.winner-highlight');
        
        // Check if we just completed a trick (went from 3 to 4 cards)
        if (currentTrickCount === 4 && this.lastTrickCount < 4 && winnerCard && !this.trickWinnerVisible) {
          // Mark that we're currently showing a winning trick
          this.trickWinnerVisible = true;
          
          // Add enhanced winner effect
          winnerCard.classList.add('winner-glow-active');
          if (winnerHighlight) {
            winnerHighlight.classList.add('highlight-active');
          }
          
          // Identify the winner seat
          const winnerCardId = winnerCard.id;
          const seatMatch = winnerCardId.match(/trick-card-(\d+)/);
          if (seatMatch) {
            const winnerSeat = seatMatch[1];
            console.log(`Trick won by player in seat ${winnerSeat}`);
          }
          
          // Set a timeout to hide the trick cards after delay
          setTimeout(() => {
            // Reset our state trackers
            this.trickWinnerVisible = false;
            this.lastTrickCount = 0;
            
            // If we're still seeing the same trick (it hasn't been updated by the server yet),
            // hide the cards with a fade-out effect
            document.querySelectorAll('[id^="trick-card-"]').forEach(card => {
              card.classList.add('fade-out');
            });
            
            // Remove the highlight
            if (winnerHighlight) {
              winnerHighlight.classList.remove('highlight-active');
            }
          }, 2000);
        }
        
        // Update our counter for the next check
        this.lastTrickCount = currentTrickCount;
      }, 200); // Check every 200ms
    },
    
    disconnected() {
      // Clear the timer when disconnected
      if (this.timer) {
        clearInterval(this.timer);
      }
    }
  }
};

export default Hooks;